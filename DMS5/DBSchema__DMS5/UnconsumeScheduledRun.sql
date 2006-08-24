/****** Object:  StoredProcedure [dbo].[UnconsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UnconsumeScheduledRun
/****************************************************
**
**	Desc:
**		moves the scheduled run associated with specified dataset 
**		from scheduled run history table back to the requested run table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/1/2004
**      1/13/2006 -- grk Handling for new blocking columns in request and history tables.
**      1/17/2006   -- grk Handling for new EUS tracking columns in request and history tables.
**      3/10/2006   -- grk Fixed logic to handle absence of associated request
**      3/10/2006   -- grk Fixed logic to handle null batchID on old requests
**    
*****************************************************/
	@datasetID int,
	@wellplateNum varchar(50),
	@wellNum varchar(50),
	@message varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

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
	declare @auto int
	set @auto = 0
	if @com LIKE 'Automatically created%'
		set @auto = 1

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	
	declare @transName varchar(32)
	set @transName = 'UnconsumeScheduledRun'
	begin transaction @transName

	---------------------------------------------------
	-- Copy scheduled run history to request table
	-- if it was not automatically created
	---------------------------------------------------	

	if @auto = 0
	begin
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
		
	end -- if @auto
	
	---------------------------------------------------
	-- Delete EUS users from history 
	---------------------------------------------------

	DELETE FROM T_Requested_Run_History_EUS_Users
	WHERE     (Request_ID = @requestID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Problem trying to delete EUS users from history table'
		rollback transaction @transName
		return 51007
	end
	
	---------------------------------------------------
	-- Delete request from history 
	---------------------------------------------------

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

	---------------------------------------------------
	-- 
	---------------------------------------------------

	commit transaction @transName
	return 0

GO
GRANT EXECUTE ON [dbo].[UnconsumeScheduledRun] TO [DMS_SP_User]
GO
