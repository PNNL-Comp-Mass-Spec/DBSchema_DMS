/****** Object:  StoredProcedure [dbo].[ConsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure ConsumeScheduledRun
/****************************************************
**
**	Desc:
**		delete the given requested run from the requested run table
**		and move it to the scheduled run history table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 2/13/2003
**		1/5/2002    grk - Added stuff for Internal Standard and cart parameters
**      3/1/2004    grk - Added validation for experiments matching between request and dataset
**      10/12/2005  grk - Added stuff to copy new work package and proposal fields.
**      1/13/2006   grk - Handling for new blocking columns in request and history tables.
**      1/17/2006   grk - Handling for new EUS tracking columns in request and history tables.
**		04/08/2008  grk - Added handling for separation field (Ticket #658)
**		03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**    
*****************************************************/
	@datasetID int,
	@requestID int,
	@message varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''


	---------------------------------------------------
	-- Validate that experiments match
	---------------------------------------------------
	
	-- get experiment ID from dataset
	--
	declare @experimentID int
	set @experimentID = 0
	--
	SELECT   @experimentID = Exp_ID
	FROM T_Dataset
	WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to look up experiment for dataset'
		RAISERROR (@message, 10, 1)
		return 51085
	end

	-- get experiment ID from scheduled run
	--
	declare @reqExperimentID int
	set @reqExperimentID = 0
	--
	SELECT   @reqExperimentID = Exp_ID
	FROM T_Requested_Run
	WHERE ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to look up experiment for request'
		RAISERROR (@message, 10, 1)
		return 51086
	end
	
	-- validate that experiments match
	--
	if @experimentID <> @reqExperimentID
	begin
		set @message = 'Experiment in dataset does not match with one in scheduled run'
		RAISERROR (@message, 10, 1)
		return 51072
	end

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	
	declare @transName varchar(32)
	set @transName = 'ConsumeScheduledRun'
	begin transaction @transName

	---------------------------------------------------
	-- Copy request to history table
	---------------------------------------------------
	
	INSERT INTO T_Requested_Run_History
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
		RDS_WorkPackage,
		RDS_Cart_ID,
		RDS_Run_Start,
		RDS_Run_Finish,
		RDS_internal_standard,
		DatasetID,
		RDS_BatchID,
		RDS_Blocking_Factor,
		RDS_Block,
		RDS_Run_Order,
		RDS_EUS_Proposal_ID, 
        RDS_EUS_UsageType,
        RDS_Sec_Sep,
        RDS_MRM_Attachment
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
		RDS_WorkPackage,
		RDS_Cart_ID,
		RDS_Run_Start,
		RDS_Run_Finish,
		RDS_Internal_Standard,
		@datasetID as DatasetID,
		RDS_BatchID,
		RDS_Blocking_Factor,
		RDS_Block,
		RDS_Run_Order,
		RDS_EUS_Proposal_ID, 
        RDS_EUS_UsageType,
        RDS_Sec_Sep,
        RDS_MRM_Attachment
	FROM T_Requested_Run
	WHERE     (ID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Failed to copy original request'
		rollback transaction @transName
		return 51007
	end
	
	---------------------------------------------------
	-- Copy EUS users to history table and get site
	-- status from EUS users table
	---------------------------------------------------
	
	INSERT INTO T_Requested_Run_History_EUS_Users
		(EUS_Person_ID, Request_ID, Site_Status)
	SELECT
		T_Requested_Run_EUS_Users.EUS_Person_ID, 
		T_Requested_Run_EUS_Users.Request_ID, 
		T_EUS_Users.Site_Status
	FROM
		T_Requested_Run_EUS_Users INNER JOIN
		T_EUS_Users ON T_Requested_Run_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID
	WHERE
		(T_Requested_Run_EUS_Users.Request_ID = @requestID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to copy EUS users'
		rollback transaction @transName
		return 51009
	end


	---------------------------------------------------
	-- Delete original request
	---------------------------------------------------
	
	exec @myError = DeleteRequestedRun
						@requestID,
						@message output
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete original request "' +  cast(@requestID as varchar(12)) + '"'
		rollback transaction @transName
		return 51007
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	commit transaction @transName
	return 0


GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [DMS_SP_User]
GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [Limited_Table_Write]
GO
