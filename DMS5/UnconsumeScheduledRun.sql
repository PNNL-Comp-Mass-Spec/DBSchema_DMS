/****** Object:  StoredProcedure [dbo].[UnconsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UnconsumeScheduledRun
/****************************************************
**
**	Desc:
**  The intent is to recycle user-entered requests
**  (where appropriate) and make sure there is
**  a requested run for each dataset (unless
**  dataset is being deleted).
**
**  Disassociates the currently-associated requested run 
**  from the given dataset if the requested run was
**  user-entered (as opposted to automatically created
**  when dataset was created with requestID = 0).
**
**  If original requested run was user-entered and @retainHistory
**  flag is set, copy the original requested run to a
**  new one and associate that one with the given dataset.
**
**  If the given dataset is to be deleted, the @retainHistory flag 
**  must be clear, otherwise a foreign key constraint will fail
**  when the attempt to delete the dataset is made and the associated
**  request is still hanging around.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/1/2004
**      01/13/2006 grk - Handling for new blocking columns in request and history tables.
**      01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**      03/10/2006 grk - Fixed logic to handle absence of associated request
**      03/10/2006 grk - Fixed logic to handle null batchID on old requests
**      05/01/2007 grk - Modified logic to optionally retain original history (Ticket #446)
**      07/17/2007 grk - Increased size of comment field (Ticket #500)
**		04/08/2008 grk - Added handling for separation field (Ticket #658)
**		03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**		02/24/2010 grk - Added handling for requested run factors
**		02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**	    03/02/2010 grk - added status field to requested run
**		08/04/2010 mem - No longer updating the "date created" date for the recycled request
**		12/13/2011 mem - Added parameter @callingUser, which is sent to CopyRequestedRun, AlterEventLogEntryUser, and DeleteRequestedRun
**		02/20/2013 mem - Added ability to lookup the original request from an auto-created recycled request
**		02/21/2013 mem - Now validating that the RequestID extracted from "Automatically created by recycling request 12345" actually exists
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@wellplateNum varchar(50),
	@wellNum varchar(50),
	@retainHistory tinyint = 0,
	@message varchar(1024) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = IsNull(@message, '')

	---------------------------------------------------
	-- get datasetID
	---------------------------------------------------
	declare @datasetID int
	set @datasetID = 0
	--
	SELECT  
		@datasetID = Dataset_ID
	FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get Id or state for dataset "' + @datasetNum + '"'
		return 51140
	end
	--
	if @datasetID = 0
	begin
		set @message = 'Dataset does not exist"' + @datasetNum + '"'
		return 51141
	end

	---------------------------------------------------
	-- Look for associated request for dataset
	---------------------------------------------------	
	declare @requestComment varchar(1024)
	declare @requestID int
	declare @requestOrigin char(4)
	
	declare @requestIDOriginal int = 0
	declare @CopyRequestedRun tinyint = 0
	declare @RecycleOriginalRequest tinyint = 0
	
	set @requestComment = ''
	set @requestID = 0
	--
	SELECT 
		@requestID = ID,
		@requestComment = RDS_comment,
		@requestOrigin = RDS_Origin
	FROM T_Requested_Run
	WHERE (DatasetID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Problem trying to find associated requested run for dataset'
		return 51006
	end

	---------------------------------------------------
	-- We are done if there is no associated request
	---------------------------------------------------	
	if @requestID = 0
	begin
		return 0
	end
	
	---------------------------------------------------
	-- Was request automatically created by dataset entry?
	---------------------------------------------------	
	--
	declare @autoCreatedRequest int = 0
	
	IF @requestOrigin = 'auto'
		set @autoCreatedRequest = 1

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	declare @notation varchar(256)
	Declare @AddnlText varchar(1024)
	
	declare @transName varchar(32)
	set @transName = 'UnconsumeScheduledRun'
	begin transaction @transName

	---------------------------------------------------
	-- Reset request
	-- if it was not automatically created
	---------------------------------------------------	

	if @autoCreatedRequest = 0
	BEGIN -- <a1>
		---------------------------------------------------
		-- original request was user-entered,
		-- We will copy it (if commanded to) and set status to 'Completed'
		---------------------------------------------------
		--		
		Set @requestIDOriginal = @requestID
		Set @RecycleOriginalRequest = 1

		If @retainHistory = 1
		Begin
			Set @CopyRequestedRun = 1
		End
		
	END -- </a1>
	ELSE
	BEGIN -- <a2>
		---------------------------------------------------
		-- original request was auto created 
		-- delete it (if commanded to)
		---------------------------------------------------
		--
		if @retainHistory = 0
		BEGIN -- <b2>
			EXEC @myError = DeleteRequestedRun
								 @requestID,
								 @message OUTPUT,
								 @callingUser 
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				return 51052
			end
		END -- </b2>
		Else
		Begin -- <b3>
		
			---------------------------------------------------
			-- original request was auto-created
			-- Examine the request comment to determine if it was a recycled request
			---------------------------------------------------
			--			
			If @requestComment Like '%Automatically created by recycling request [0-9]%[0-9] from dataset [0-9]%'
			Begin -- <c>
			
				-- Determine the original request ID
				--		
				Declare @CharIndex int
				Declare @Extracted varchar(1024)
				Declare @OriginalRequestStatus varchar(32) = ''
				Declare @OriginalRequesetDatasetID int = 0
						       
				Set @CharIndex = CHARINDEX('by recycling request', @requestComment)
				
				If @CharIndex > 0
				Begin -- <d>
					Set @Extracted = LTRIM(SUBSTRING(@requestComment, @CharIndex + LEN('by recycling request'), 20))					
					
					-- Comment is now of the form: "286793 from dataset"
					-- Find the space after the number
					--	
					Set @CharIndex = CHARINDEX(' ', @Extracted)
					
					If @CharIndex > 0
					Begin -- <e>
						Set @Extracted = LTRIM(RTRIM(SUBSTRING(@Extracted, 1, @Charindex)))
						
						-- Original requested ID has been determined; copy the original request
						--							
						Set @requestIDOriginal = Convert(int, @Extracted)
						Set @RecycleOriginalRequest = 1
						
						-- Make sure the original request actually exists
						IF Not Exists (SELECT * FROM T_Requested_Run WHERE ID = @requestIDOriginal)
						Begin
							-- Original request doesn't exist; recycle this recycled one
							Set @requestIDOriginal = @RequestID
						End

						-- Make sure that the original request is not active
						-- In addition, lookup the dataset ID of the original request
						
						SELECT @OriginalRequestStatus = RDS_Status, 
						       @OriginalRequesetDatasetID = DatasetID
						FROM T_Requested_Run 
						WHERE ID = @requestIDOriginal
						
						If @OriginalRequestStatus = 'Active' 
						Begin							
							-- The original request is active, don't recycle anything
							
							If @requestIDOriginal = @requestID
							Begin
								Set @AddnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetNum + ' since it is already active'
								Exec PostLogEntry 'Warning', @AddnlText, 'UnconsumeScheduledRun'
								
								Set @AddnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' since it is already active'
								Set @message = dbo.AppendToText(@message, @AddnlText, 0, '; ')
							End
							Else
							Begin
								Set @AddnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetNum + ' since dataset already has an active request (' + @Extracted + ')'
								Exec PostLogEntry 'Warning', @AddnlText, 'UnconsumeScheduledRun'
								
								Set @AddnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' since dataset already has an active request (' + @Extracted + ')'
								Set @message = dbo.AppendToText(@message, @AddnlText, 0, '; ')
							End
							
							Set @requestIDOriginal = 0							
						End
						Else
						Begin
							Set @CopyRequestedRun = 1
							Set @datasetID = @OriginalRequesetDatasetID
						End
							
					End -- </e>
				End -- </d>
			End -- </c>
			Else
			Begin
				Set @AddnlText = 'Not recycling request ' + Convert(varchar(12), @requestID) + ' for dataset ' + @datasetNum + ' since AutoRequest'
				Set @message = dbo.AppendToText(@message, @AddnlText, 0, '; ')
			End
			
		End -- </b3>
		
	END -- <a2>


	If @requestIDOriginal > 0 And @CopyRequestedRun = 1
	BEGIN -- <a3>
	
		---------------------------------------------------
		-- Copy the request and associate the dataset with the newly created request
		---------------------------------------------------
		--
		-- Warning: The text "Automatically created by recycling request" is used earlier in this stored procedure; thus, do not update it here
		--
		set @notation = 'Automatically created by recycling request ' + cast(@requestIDOriginal as varchar(12)) + ' from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101)
		--
		EXEC @myError = CopyRequestedRun
								@requestIDOriginal,
								@datasetID,
								'Completed',
								@notation,
								@message output,
								@callingUser
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			return @myError
		end		
	END -- </a3>


	If @requestIDOriginal > 0 And @RecycleOriginalRequest = 1
	Begin -- <a4>
	
		---------------------------------------------------
		-- Recycle the original request
		---------------------------------------------------	
		--
	    -- create annotation to be appended to comment
	    --
		set @notation = ' (recycled from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101) + ')'
		if len(@requestComment) + len(@notation) > 1024
		begin
			-- Dataset comment could become too long; do not append the additional note
			set @notation = ''
		end
		
		-- Reset the requested run to 'Active'
		-- Do not update RDS_Created; we want to keep it as the original date for planning purposes
		--
		Declare @newStatus varchar(24) = 'Active'
		
		UPDATE
			T_Requested_Run
		SET
			RDS_Status = @newStatus,
			RDS_Run_Start = NULL,
			RDS_Run_Finish = NULL,
			DatasetID = NULL,
			RDS_comment = RDS_comment + @notation
		WHERE 
			ID = @requestIDOriginal
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying reset request'
			rollback transaction @transName
			return 51007
		end

		If Len(@callingUser) > 0
		Begin
			Declare @stateID int = 0

			SELECT @stateID = State_ID
			FROM T_Requested_Run_State_Name
			WHERE (State_Name = @newStatus)

			Exec AlterEventLogEntryUser 11, @requestIDOriginal, @stateID, @callingUser
		End


	End -- </a4>
	
	
	---------------------------------------------------
	-- Commit the changes
	---------------------------------------------------

	commit transaction @transName
	return 0

GO
GRANT EXECUTE ON [dbo].[UnconsumeScheduledRun] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UnconsumeScheduledRun] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UnconsumeScheduledRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UnconsumeScheduledRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UnconsumeScheduledRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UnconsumeScheduledRun] TO [PNL\D3M580] AS [dbo]
GO
