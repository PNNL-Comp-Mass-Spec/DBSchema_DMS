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
**  datset is being deleted).
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
**  when the attemp to delete the dataset is made and the associated
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
**    
*****************************************************/
	@datasetNum varchar(128),
	@wellplateNum varchar(50),
	@wellNum varchar(50),
	@retainHistory tinyint = 0,
	@message varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

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
		set @message = 'Datset does not exist"' + @datasetNum + '"'
		return 51141
	end

	---------------------------------------------------
	-- Look for associated request for dataset
	---------------------------------------------------	
	declare @com varchar(1024)
	set @com = ''
	declare @requestID int
	set @requestID = 0
	DECLARE @requestOrigin CHAR(4)
	--
	SELECT 
		@requestID = ID,
		@com = RDS_comment,
		@requestOrigin = RDS_Origin
	FROM T_Requested_Run
	WHERE (DatasetID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Problem trying to find associated requested run history for dataset'
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
	declare @autoCreatedRequest int
	set @autoCreatedRequest = 0
--	if @com LIKE '%Automatically created%'
	IF @requestOrigin = 'auto'
		set @autoCreatedRequest = 1

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	declare @notation varchar(256)
	
	declare @transName varchar(32)
	set @transName = 'UnconsumeScheduledRun'
	begin transaction @transName

	---------------------------------------------------
	-- Reset request
	-- if it was not automatically created
	---------------------------------------------------	

	if @autoCreatedRequest = 0
	BEGIN --<a>
		---------------------------------------------------
		-- original request was user-entered,
		-- copy it (if commanded to) 
		-- and set status to 'Completed'
		---------------------------------------------------
		--
		if  @retainHistory > 0
		BEGIN --<c>
			set @notation = 'Automatically created by recycling request ' + cast(@requestID as varchar(12)) + ' from dataset ' + cast(@datasetID as varchar(12)) 
			--
			EXEC @myError = CopyRequestedRun
									@requestID,
									@datasetID,
									'Completed',
									@notation,
									@message output
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				return @myError
			end
		END --<c>
		--
		---------------------------------------------------
		-- always recycle original
		---------------------------------------------------	
		--
	    -- create annotation to be appended to comment
	    --
		set @notation = ' (recycled from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101) + ')'
		if len(@com) + len(@notation) > 1024
			set @notation = ''
		--
		UPDATE
			T_Requested_Run
		SET
			RDS_Status = 'Active',
			RDS_Run_Start = NULL,
			RDS_Run_Finish = NULL,
			DatasetID = NULL,
			RDS_comment = RDS_comment + @notation,
			RDS_created = GETDATE()
		WHERE 
			ID = @requestID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying reset request'
			rollback transaction @transName
			return 51007
		end

	END --<a>
	ELSE
	BEGIN --<b>
		---------------------------------------------------
		-- original request was auto created 
		-- delete it (if commanded to)
		---------------------------------------------------
		--
		if  @retainHistory = 0
		BEGIN --<d>
			EXEC @myError = DeleteRequestedRun
								 @requestID,
								 @message OUTPUT 
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				return 51052
			end
		END --<d>
	END --<b>

	---------------------------------------------------
	-- 
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
GRANT VIEW DEFINITION ON [dbo].[UnconsumeScheduledRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UnconsumeScheduledRun] TO [PNL\D3M580] AS [dbo]
GO
