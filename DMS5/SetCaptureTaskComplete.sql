/****** Object:  StoredProcedure [dbo].[SetCaptureTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure dbo.SetCaptureTaskComplete
/****************************************************
**
**	Desc: Sets state of dataset record given by @datasetNum
**        according to given completion code and 
**        adjusts related database entries accordingly.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**			11/04/2002
**  		08/06/2003 grk - added handling for "Not Ready" state
**  		11/13/2003 dac - changed "FTICR" instrument class to "Finnigan_FTICR" following instrument class renaming
**  		06/21/2005 grk - added handling "requires_preparation" 
**  		09/25/2007 grk - return result from DoDatasetCompletionActions (http://prismtrac.pnl.gov/trac/ticket/537)
**  		10/09/2007 grk - limit number of retries (ticket 537)
**  		12/16/2007 grk - add completion code '100' for use by capture broker
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			04/04/2012 mem - Added parameter @FailureMessage
**			08/19/2015 mem - If @completionCode is 0, now looking for and removing messages of the form "Error while copying \\15TFTICR64\data\"
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode = 1 -> failure, @completionCode = 2 -> not ready, 100 -> success (capture broker)
	@message varchar(512) output,
	@FailureMessage varchar(512) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	Set @FailureMessage = IsNull(@FailureMessage, '')
	
	declare @maxRetries int
	set @maxRetries = 20
	
	declare @datasetID int
	declare @datasetState int
	declare @completionState int
 	declare @result int
	declare @instrumentClass varchar(32)
	declare @doPrep tinyint
	declare @Comment varchar(512)
	
   	---------------------------------------------------
	-- resolve dataset into instrument class
	---------------------------------------------------
	--
	SELECT @datasetID = T_Dataset.Dataset_ID,
	       @instrumentClass = T_Instrument_Name.IN_class,
	       @doPrep = T_Instrument_Class.requires_preparation,
	       @Comment = T_Dataset.DS_Comment
	FROM T_Dataset
	     INNER JOIN T_Instrument_Name
	       ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
	     INNER JOIN T_Instrument_Class
	       ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset ID for dataset ' + @datasetNum
		goto done
	end
	
   	---------------------------------------------------
	-- choose completion state
	---------------------------------------------------
	
	if @completionCode = 0
		begin
			if @doPrep > 0
				set @completionState = 6 -- received
			else
				set @completionState = 3 -- normal completion
		end	
	else if @completionCode = 1
		begin
			set @completionState = 5 -- capture failed
		end
	else if @completionCode = 2
		begin
			set @completionState = 9 -- dataset not ready
		end
	else if @completionCode = 100
		begin
			set @completionState = 3 -- normal completion
		end
	
   	---------------------------------------------------
	-- limit number of retries
	---------------------------------------------------

	if @completionState = 9
	begin
		SELECT @result = COUNT(*)
		FROM T_Event_Log
		WHERE (Target_Type = 4) AND
		      (Target_State = 1) AND
		      (Prev_Target_State = 2 OR
		       Prev_Target_State = 5) AND
		      (Target_ID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error checking for retry count ' + @datasetNum
			goto done
		end
		--
		if @result > @maxRetries
		begin
			set @completionState = 5 -- capture failed
			set @message = 'Number of capture retries exceeded limit of ' + cast(@maxRetries as varchar(12)) + ' for dataset "' + @datasetNum + '"'
			exec PostLogEntry
					'Error', 
					@message, 
					'SetCaptureTaskComplete'
			set @message = ''
		end
	end

   	---------------------------------------------------
	-- perform the actions necessary when dataset is complete
	---------------------------------------------------
	--
	execute @myError = DoDatasetCompletionActions @datasetNum, @completionState, @message output

   	---------------------------------------------------
	-- Update the comment as needed
	---------------------------------------------------
	--
	Set @Comment = IsNull(@Comment, '')
	
	If @completionState = 3
	Begin
		-- Dataset successfully captured
		-- Remove error messages of the form Error while copying \\15TFTICR64\data\ ...
		
		Declare @CommentLengthCached int = Len(@Comment)
		Declare @matchIndex int = CharIndex('; Error while copying \\', @Comment)
		
		If @matchIndex = 0
		Begin
			Set @matchIndex = CharIndex('Error while copying \\', @Comment)
		End
		
		If @matchIndex = 1
		Begin
			Set @Comment = ''
		End
		
		If @matchIndex > 1
		Begin
			-- Match found; remove the error message
			Set @Comment = RTrim(Substring(@Comment, 1, @matchIndex - 1))
		End
						
		If Len(@Comment) <> @CommentLengthCached
		Begin
			
			UPDATE T_Dataset
			SET DS_Comment = @Comment
			WHERE Dataset_ID = @DatasetID
			
		End
		
	End
	
	If @completionState = 5 And @FailureMessage <> ''
	Begin
		-- Add @FailureMessage to the dataset comment (if not yet present)
		Set @Comment = dbo.AppendToText(@Comment, @FailureMessage, 0, '; ')	
		
		UPDATE T_Dataset
		SET DS_Comment = @Comment
		WHERE Dataset_ID = @DatasetID
			
	End

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetCaptureTaskComplete', @UsageMessage

	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[SetCaptureTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetCaptureTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
