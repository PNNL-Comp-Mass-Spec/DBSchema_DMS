/****** Object:  StoredProcedure [dbo].[UnconsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UnconsumeScheduledRun
/****************************************************
**
**	Desc:
**	  Dissassociates from the given dataset, the request that is 
**    currently associated with it in the history table.
** 
**    If the request was originally entered in the request table
**    (that is, it was not automatically created by the dataset 
**    entry process with request set to 0) then it will be copied 
**    from the request history table back to the request table 
**    (with its original request ID).
**
**    If the @retainHistory flag is clear, the original request
**    in the history table will be deleted from the history table.
**
**    If the @retainHistory flag is set and the original request
**    was automatically created, it will be left untouched 
**    (and will remain associated with the given dataset).
** 
**    If the @retainHistory flag is set and the original request 
**    was NOT automatically created, it will be given a new request ID 
**    (and will remain associated with the given dataset).  This is
**    necessary since a copy of the request was put back into
**    the request table with its original ID, and duplicates are
**    not allowed.
**
**    If the given dataset is to be deleted, the @retainHistory flag 
**    must be clear, otherwise a foreign key constraint will fail
**    when the attemp to delete the dataset is made and the associated
**    request is still hanging around.
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
	declare @com varchar(255)
	set @com = ''
	declare @requestID int
	set @requestID = 0
	--
	SELECT 
		@requestID = ID,
		@com = RDS_comment
	FROM T_Requested_Run_History
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
	declare @autoCreatedHistoricalRequest int
	set @autoCreatedHistoricalRequest = 0
	if @com LIKE '%Automatically created%'
		set @autoCreatedHistoricalRequest = 1

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	declare @notation varchar(256)
	
	declare @transName varchar(32)
	set @transName = 'UnconsumeScheduledRun'
	begin transaction @transName

	---------------------------------------------------
	-- Copy scheduled run history to request table
	-- if it was not automatically created
	---------------------------------------------------	

	if @autoCreatedHistoricalRequest = 0
	begin
		set @notation = ' (recycled from dataset ' + cast(@datasetID as varchar(12)) + ' on ' + CONVERT (varchar(12), getdate(), 101) + ')'
		---------------------------------------------------
		-- Copy run history to scheduled run
		---------------------------------------------------	
		INSERT INTO T_Requested_Run
		(
			RDS_Name,
			RDS_Oper_PRN,
			RDS_comment,
			RDS_created,
			RDS_instrument_name,
			RDS_type_ID,
			RDS_instrument_setting,
			RDS_special_instructions,
			RDS_note,
			Exp_ID,
			ID,
			RDS_Cart_ID,
			RDS_Run_Start,
			RDS_Run_Finish,
			RDS_internal_standard, 
			RDS_Well_Plate_Num, 
			RDS_Well_Num,
			RDS_priority,
			RDS_BatchID,
			RDS_Blocking_Factor,
			RDS_Block,
			RDS_Run_Order,
			RDS_EUS_Proposal_ID, 
			RDS_EUS_UsageType
		)
		SELECT
			RDS_Name,
			RDS_Oper_PRN,
			RDS_comment + @notation,
			RDS_created,
			RDS_instrument_name,
			RDS_type_ID,
			RDS_instrument_setting,
			RDS_special_instructions,
			RDS_note,
			Exp_ID,
			ID,
			1, -- RDS_Cart_ID
			NULL, -- RDS_Run_Start
			NULL, -- RDS_Run_Finish
			RDS_internal_standard,
			@wellplateNum, 
			@wellNum, 
			1,
			ISNULL(RDS_BatchID , 0),
			RDS_Blocking_Factor,
			RDS_Block,
			RDS_Run_Order,
			RDS_EUS_Proposal_ID, 
			RDS_EUS_UsageType
		FROM T_Requested_Run_History
		WHERE     (DatasetID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying to copy original scheduled run'
			rollback transaction @transName
			return 51007
		end

		---------------------------------------------------
		-- Copy proposal users from history to scheduled run
		---------------------------------------------------	
		INSERT INTO T_Requested_Run_EUS_Users
							(EUS_Person_ID, Request_ID)
		SELECT     EUS_Person_ID, Request_ID
		FROM         T_Requested_Run_History_EUS_Users
		WHERE     (Request_ID = @requestID)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying to copy EUS users'
			rollback transaction @transName
			return 51007
		end
		
	end -- if @autoCreatedHistoricalRequest

	---------------------------------------------------
	-- Deal with original history 
	---------------------------------------------------
	-- Note: this depends on cascade behavior with foreign keys
	-- in T_Requested_Run_History_EUS_Users in order to work properly

	---------------------------------------------------
	-- if we ARE NOT retaining a copy of the uncomsumed request to
	-- be associated with the dataset, delete the entry in the history
	-- table
	--
	if @retainHistory = 0
	begin
		-- delete entry from history table
		--
		DELETE FROM T_Requested_Run_History
		WHERE     (DatasetID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying to delete request from history'
			rollback transaction @transName
			return 51007
		end
	end

	---------------------------------------------------
	-- if we ARE retaining a copy of the uncomsumed request to
	-- be associated with the dataset, renumber the entry in the history
	-- table, but only if it was copied back to the request table
	--
	if  @retainHistory <> 0 and @autoCreatedHistoricalRequest = 0
	begin
		-- runumber existing history entry
		--
		-- get new ID number for existing request in history
		--
		declare @newReqID int
		set @newReqID = dbo.GetNewRequestedRunID()
		if @newReqID = 0
		begin
			set @message = 'Problem trying to get new request ID for renumbering'
			rollback transaction @transName
			return 51008
		end
		-- renumber existing history request
		-- and annotate it as having been automatically created 
		-- so that it will not be unconsumed if dataset is subsequently deleted
		--
		set @notation = 'Automatically created by recycling request ' + cast(@requestID as varchar(12)) + ' from dataset ' + cast(@datasetID as varchar(12)) 
		UPDATE T_Requested_Run_History
		SET 
			ID = @newReqID,
			RDS_comment = @notation
		WHERE (ID = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Problem trying to renumber request in history'
			rollback transaction @transName
			return 51009
		end
	end -- if @retainHistory and @autoCreatedHistoricalRequest

	---------------------------------------------------
	-- 
	---------------------------------------------------

	commit transaction @transName
	return 0

GO
GRANT EXECUTE ON [dbo].[UnconsumeScheduledRun] TO [DMS_SP_User]
GO
