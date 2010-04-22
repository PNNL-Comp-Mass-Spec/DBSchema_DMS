/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[AddUpdateRequestedRun]
/****************************************************
**
**	Desc:	Adds a new entry to the requested dataset table
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/11/2002
**			02/15/2003
**			12/05/2003 grk - added wellplate stuff
**			01/05/2004 grk - added internal standard stuff
**			03/01/2004 grk - added manual identity calculation (removed identity column)
**			03/10/2004 grk - repaired manual identity calculation to include history table
**			07/15/2004 grk - added verification of experiment location aux info
**			11/26/2004 grk - changed type of @comment from text to varchar
**			01/12/2004 grk - fixed null return on check existing when table is empty
**			10/12/2005 grk - Added stuff for new work package and proposal fields.
**			02/21/2006 grk - Added stuff for EUS proposal and user tracking.
**			11/09/2006 grk - Fixed error message handling (Ticket #318)
**			01/12/2007 grk - added verification mode
**			01/31/2007 grk - added verification for @operPRN (Ticket #371)
**			03/19/2007 grk - added @defaultPriority (Ticket #421) (set it back to 0 on 04/25/2007)
**			04/25/2007 grk - get new ID from UDF (Ticket #446)
**			04/30/2007 grk - added better name validation (Ticket #450)
**			07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**			07/11/2007 grk - modified to look up EUS fields from sample prep request (Ticket #499)
**			07/17/2007 grk - Increased size of comment field (Ticket #500)
**			07/30/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**			09/06/2007 grk - factored out instrument name and dataset type validation to ValidateInstrumentAndDatasetType (Ticket #512)
**			09/06/2007 grk - added call to LookupInstrumentRunInfoFromExperimentSamplePrep (Ticket #512)
**			09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**			02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**			04/09/2008 grk - Added secondary separation field (Ticket #658)
**			03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          06/03/2009 grk - look up work package (Ticket #739) 
**			07/27/2009 grk - added lookup for wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**			02/28/2010 grk - added add-auto mode
**			03/02/2010 grk - added status field to requested run
**			03/10/2010 grk - fixed issue with status validation
**			03/27/2010 grk - fixed problem creating new requests with "Completed" status.
**
*****************************************************/
(
	@reqName varchar(128),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@workPackage varchar(50),
	@msType varchar(20),
	@instrumentSettings varchar(512) = 'na',
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(24) = 'na',
	@internalStandard varchar(50) = 'na',
	@comment varchar(1024) = 'na',
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@request int output,
	@message varchar(512) output,
	@secSep varchar(64) = 'LC-ISCO-Standard',
	@MRMAttachment varchar(128),
	@status VARCHAR(24) = 'Active'
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(512)
	declare @InstrumentMatch varchar(64)
		
	-- default priority at which new requests will be created
	declare @defaultPriority int
	set @defaultPriority = 0
	
	---------------------------------------------------
	--
	---------------------------------------------------
	--
	DECLARE @requestOrigin CHAR(4)
	SET @requestOrigin = 'user'
	--
	IF @mode = 'add-auto'
	BEGIN
		SET @mode = 'add'
		SET @requestOrigin = 'auto'
	END  
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@reqName) < 1
	begin
		set @myError = 51110
		RAISERROR ('Dataset number was blank',
			10, 1)
	end
	--
	if LEN(@experimentNum) < 1
	begin
		set @myError = 51111
		RAISERROR ('Experiment number was blank',
			10, 1)
	end
	--
	if LEN(@operPRN) < 1
	begin
		set @myError = 51113
		RAISERROR ('Operator payroll number/HID was blank',
			10, 1)
	end
	--
	if LEN(@instrumentName) < 1
	begin
		set @myError = 51114
		RAISERROR ('Instrument name was blank',
			10, 1)
	end
	--
	if LEN(@msType) < 1
	begin
		set @myError = 51115
		RAISERROR ('Dataset type was blank',
			10, 1)
	end
	--
	if LEN(@workPackage) < 1
	begin
		set @myError = 51115
		RAISERROR ('Work package was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- validate name
	---------------------------------------------------

	declare @badCh varchar(128)
	set @badCh =  dbo.ValidateChars(@reqName, '')
	if @badCh <> ''
	begin
		If @badCh = '[space]'
			set @msg = 'Requested run name may not contain spaces'
		Else
			set @msg = 'Requested run name may not contain the character(s) "' + @badCh + '"'

		RAISERROR (@msg, 10, 1)
		return 51001
	end
		
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @requestID int
	set @requestID = 0
	declare @oldEusProposalID varchar(10)
	set @oldEusProposalID = ''
	DECLARE @oldStatus VARCHAR(24)
	SET @oldStatus = ''
	--
	SELECT 
		@requestID = ISNULL(ID, 0), 
		@oldEusProposalID = RDS_EUS_Proposal_ID,
		@oldStatus = RDS_Status
	FROM T_Requested_Run
	WHERE (RDS_Name = @reqName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to find existing request: "' + @reqName + '"'
		RAISERROR (@msg, 10, 1)
		return 51007
	end
	
	-- need non-null request even if we are just checking
	--
	set @request = @requestID

	-- cannot create an entry that already exists
	--
	if @requestID <> 0 and (@mode = 'add' or @mode = 'check_add')
	begin
		set @msg = 'Cannot add: Requested Dataset "' + @reqName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
	-- need non-null request even if we are just checking
	--
	set @request = @requestID

	-- cannot update a non-existent entry
	--
	if @requestID = 0 and (@mode = 'update' or @mode = 'check_update')
	begin
		set @msg = 'Cannot update: Requested Dataset "' + @reqName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
	---------------------------------------------------
	--
	---------------------------------------------------
	--
	IF @Mode = 'add' AND @status ='Completed'
		SET @status = 'Active'
	--
	IF @Mode = 'add' AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
	BEGIN
		set @msg = 'Status "' + @status + '" is not valid'
		RAISERROR (@msg, 10, 1)
		return 51037
	END 
	--
	IF @Mode = 'update' AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
	BEGIN
		set @msg = 'Status "' + @status + '" is not valid'
		RAISERROR (@msg, 10, 1)
		return 51037
	END 
	--
	IF @Mode = 'update' AND (@status ='Completed' AND @oldStatus <> 'Completed' )
	BEGIN
		set @msg = 'Cannot set status of request to "Completed"'
		RAISERROR (@msg, 10, 1)
		return 51039
	END
	--
	IF @Mode = 'update' AND (@oldStatus = 'Completed' AND @status <> 'Completed')
	BEGIN
		set @msg = 'Cannot change status of a request that has been consumed by a dataset'
		RAISERROR (@msg, 10, 1)
		return 51039
	END 
/*
	---------------------------------------------------
	-- get experiment ID from experiment number 
	-- (and validate that it exists in database)
	---------------------------------------------------

	declare @experimentID int
	execute @experimentID = GetExperimentID @experimentNum
	if @experimentID = 0
	begin
		RAISERROR ('Could not find entry in database for experimentNum "%s"',
			10, 1, @experimentNum)
		return 51117
	end
*/
	---------------------------------------------------
	-- get experiment ID from experiment number 
	-- (and validate that it exists in database)
	-- Also set wellplate and well from experiment
	-- if called for
	---------------------------------------------------

	declare @experimentID int

	SELECT 
		@experimentID = Exp_ID, 
		@wellplateNum = case when @wellplateNum = '(lookup)' then EX_wellplate_num else @wellplateNum end,
		@wellNum = case when @wellNum = '(lookup)' then EX_well_num else @wellNum end
	FROM T_Experiments
	WHERE Experiment_Num = @experimentNum
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		RAISERROR ('Error looking up experiment', 10, 1)
		return 51117
	end
	--
	if @experimentID = 0
	begin
		RAISERROR ('Could not find entry in database for experimentNum "%s"',
			10, 1, @experimentNum)
		return 51117
	end

	---------------------------------------------------
	-- verify user ID for operator PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @operPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for operator PRN "' + @operPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51019
	end

	---------------------------------------------------
	-- Lookup instrument run info fields 
	-- (only effective for experiments
	-- that have associated sample prep requests)
	---------------------------------------------------

	exec @myError = LookupInstrumentRunInfoFromExperimentSamplePrep
						@experimentNum,
						@instrumentName output,
						@msType output,
						@instrumentSettings output,
						@message output
	if @myError <> 0
	begin
		set @message = 'LookupInstrumentRunInfoFromExperimentSamplePrep: ' + @message
		RAISERROR (@message, 10, 1)
		return @myError
	end	
	
	---------------------------------------------------
	-- validate instrument name and dataset type
	---------------------------------------------------
	declare @instrumentID int
	declare @datasetTypeID int
	--
	exec @myError = ValidateInstrumentAndDatasetType
							@msType,
							@instrumentName,
							@instrumentID output,
							@datasetTypeID output,
							@message output 
	if @myError <> 0
	begin
		set @message = 'ValidateInstrumentAndDatasetType: ' + @message
		RAISERROR (@message, 10, 1)
		return @myError
	end	

	---------------------------------------------------
	-- Resolve ID for @secSep
	---------------------------------------------------

	declare @sepID int
	set @sepID = 0
	--
	SELECT @sepID = SS_ID
	FROM T_Secondary_Sep
	WHERE SS_name = @secSep	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up separation type ID'
		RAISERROR (@msg, 10, 1)
		return 51098
	end
	if @sepID = 0
	begin
		set @msg = 'Could not resolve separation type to ID'
		RAISERROR (@msg, 10, 1)
		return 51099
	end

	---------------------------------------------------
	-- Resolve ID for MRM attachment
	---------------------------------------------------
	--
	declare @mrmAttachmentID int
	--
	set @MRMAttachment = ISNULL(@MRMAttachment, '')
	if @MRMAttachment <> ''
	begin
		SELECT @mrmAttachmentID = ID
		FROM T_Attachments
		WHERE Attachment_Name = @MRMAttachment
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to look up attachement ID'
			RAISERROR (@msg, 10, 1)
			return 51073
		end
	end
	---------------------------------------------------
	-- Lookup EUS field (only effective for experiments
	-- that have associated sample prep requests)
	---------------------------------------------------
	exec @myError = LookupEUSFromExperimentSamplePrep	
						@experimentNum,
						@eusUsageType output,
						@eusProposalID output,
						@eusUsersList output,
						@msg output
	if @myError <> 0
	begin
		RAISERROR (@msg, 10, 1)
		return @myError
	end

	---------------------------------------------------
	-- validate EUS type, proposal, and user list
	---------------------------------------------------
	declare @eusUsageTypeID int
	exec @myError = ValidateEUSUsage
						@eusUsageType,
						@eusProposalID output,
						@eusUsersList output,
						@eusUsageTypeID output,
						@msg output
	if @myError <> 0
	begin
		RAISERROR (@msg, 10, 1)
		return @myError
	end

	declare @transName varchar(32)
	set @transName = 'AddUpdateRequestedRun'

	---------------------------------------------------
	-- Lookup misc fields (only effective for experiments
	-- that have associated sample prep requests)
	---------------------------------------------------
	exec @myError = LookupOtherFromExperimentSamplePrep 
						@experimentNum, 
						@workPackage output, 
						@message  output
	if @myError <> 0
	begin
		RAISERROR (@msg, 10, 1)
		return @myError
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
	
		-- Start transaction
		--
		begin transaction @transName
		
		INSERT INTO T_Requested_Run
			(
				RDS_name, 
				RDS_Oper_PRN, 
				RDS_comment, 
				RDS_created, 
				RDS_instrument_name, 
				RDS_type_ID, 
				RDS_instrument_setting, 
				RDS_priority, 
				Exp_ID,
				RDS_WorkPackage, 
				RDS_Well_Plate_Num,
				RDS_Well_Num,
				RDS_internal_standard,
				RDS_EUS_Proposal_ID,
				RDS_EUS_UsageType,
				RDS_Sec_Sep,
				RDS_MRM_Attachment,
				RDS_Origin,
				RDS_Status
			) 
			VALUES 
			(
				@reqName, 
				@operPRN, 
				@comment, 
				GETDATE(), 
				@instrumentName, 
				@datasetTypeID, 
				@instrumentSettings, 
				@defaultPriority, -- priority
				@experimentID,
				@workPackage,
				@wellplateNum,
				@wellNum,
				@internalStandard,
				@eusProposalID,
				@eusUsageTypeID,
				@secSep,
				@mrmAttachmentID,
				@requestOrigin,
				@status
			)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @reqName + '"'
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		
		set @request = IDENT_CURRENT('T_Requested_Run')
		
		-- assign users to the request
		--
		exec @myError = AssignEUSUsersToRequestedRun
								@request,
								@eusProposalID,
								@eusUsersList,
								@msg output
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51019
		end

		commit transaction @transName

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin	
		begin transaction @transName

		set @myError = 0
		--
		UPDATE T_Requested_Run 
		SET 
			RDS_Oper_PRN = @operPRN, 
			RDS_comment = @comment, 
			RDS_instrument_name = @instrumentName, 
			RDS_type_ID = @datasetTypeID, 
			RDS_instrument_setting = @instrumentSettings, 
			Exp_ID = @experimentID,
			RDS_WorkPackage = @workPackage, 
			RDS_Well_Plate_Num = @wellplateNum,
			RDS_Well_Num = @wellNum,
			RDS_internal_standard = @internalStandard,
			RDS_EUS_Proposal_ID = @eusProposalID,
			RDS_EUS_UsageType = @eusUsageTypeID,
			RDS_Sec_Sep = @secSep,
			RDS_MRM_Attachment = @mrmAttachmentID,
			RDS_Status = @status,
			RDS_created = CASE WHEN @oldStatus = 'Inactive' AND @status = 'Active' THEN GETDATE() ELSE RDS_created END
		WHERE (ID = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @reqName + '"'
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51004
		end

		-- assign users to the request
		--
		exec @myError = AssignEUSUsersToRequestedRun
								@request,
								@eusProposalID,
								@eusUsersList,
								@msg output
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR (@msg, 10, 1)
			return 51019
		end		

		commit transaction @transName
	end -- update mode

	return 0


GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [PNL\D3M580] AS [dbo]
GO
