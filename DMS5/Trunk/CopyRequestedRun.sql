/****** Object:  StoredProcedure [dbo].[CopyRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CopyRequestedRun
/****************************************************
**
**  Desc:
**  Make copy of given requested run and associate
**  it with given dataset
**
**	Auth:	grk
**	Date:	02/26/2010
**			03/03/2010 grk - added status field
**			08/04/2010 mem - Now using the Created date from the original request as the Created date for the new request
**
*****************************************************/
	@requestID int,
	@datasetID int,
	@status VARCHAR(24),
	@notation varchar(256),
	@message varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- We are done if there is no associated request
	---------------------------------------------------
	--
	if @requestID = 0
	begin
		goto Done
	end

	---------------------------------------------------
	-- make copy
	---------------------------------------------------
	--
	-- make new request
	--
	INSERT INTO T_Requested_Run
	(
		RDS_comment,
		RDS_Name,
		RDS_Oper_PRN,
		RDS_created,
		RDS_instrument_name,
		RDS_type_ID,
		RDS_instrument_setting,
		RDS_special_instructions,
		RDS_Well_Plate_Num,
		RDS_Well_Num,
		RDS_priority,
		RDS_note,
		Exp_ID,
		RDS_Run_Start,
		RDS_Run_Finish,
		RDS_internal_standard,
		RDS_WorkPackage,
		RDS_BatchID,
		RDS_Blocking_Factor,
		RDS_Block,
		RDS_Run_Order,
		RDS_EUS_Proposal_ID,
		RDS_EUS_UsageType,
		RDS_Cart_ID,
		RDS_Cart_Col,
		RDS_Sec_Sep,
		RDS_MRM_Attachment,
		RDS_Status,
		RDS_Origin,
		DatasetID
	)
	SELECT TOP(1) -- shouldn't be any duplicates, but let's not make mistakes any worse
		@notation,
		RDS_Name,
		RDS_Oper_PRN,
		RDS_created,				-- Pass along the original request's "created" date into the new entry
		RDS_instrument_name,
		RDS_type_ID,
		RDS_instrument_setting,
		RDS_special_instructions,
		RDS_Well_Plate_Num,
		RDS_Well_Num,
		RDS_priority,
		RDS_note,
		Exp_ID,
		RDS_Run_Start,
		RDS_Run_Finish,
		RDS_internal_standard,
		RDS_WorkPackage,
		RDS_BatchID,
		RDS_Blocking_Factor,
		RDS_Block,
		RDS_Run_Order,
		RDS_EUS_Proposal_ID,
		RDS_EUS_UsageType,
		RDS_Cart_ID,
		RDS_Cart_Col,
		RDS_Sec_Sep,
		RDS_MRM_Attachment,
		@status,
		'auto',
		CASE WHEN ISNULL(@datasetID, 0) = 0 THEN NULL ELSE @datasetID END 
	FROM
		T_Requested_Run AS T_Requested_Run_1
	WHERE
		ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Problem trying to renumber request in history'
		goto Done
	end
	--
	declare @newReqID int
	set @newReqID = IDENT_CURRENT('T_Requested_Run')
	--
	-- copy factors from the request being unconsumed to the 
	-- renumbered copy being retained in the history
	--
	EXEC @myError = UpdateRequestedRunCopyFactors 
						@requestID,
						@newReqID,
						@message OUTPUT,
						'(unconsume)'
	--
	if @myError <> 0
	begin
		set @message = 'Problem copying factors to new request'
		goto Done
	end

	---------------------------------------------------
	-- Copy proposal users for new auto request
	-- from original request
	---------------------------------------------------	
	--
	INSERT INTO T_Requested_Run_EUS_Users
		(EUS_Person_ID, Request_ID)
	SELECT
		EUS_Person_ID, @newReqID
	FROM
		T_Requested_Run_EUS_Users
	WHERE
		Request_ID = @requestID		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Problem trying to copy EUS users'
		goto Done
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
Done:
	return @myError
GO
