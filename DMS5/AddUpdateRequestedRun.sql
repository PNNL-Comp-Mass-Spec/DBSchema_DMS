/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateRequestedRun
/****************************************************
**
**	Desc: Adds a new entry to the requested dataset table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/11/2002
**		Date: 2/15/2003
**      12/5/2003 grk - added wellplate stuff
**      1/5/2004 grk - added internal standard stuff
**      3/1/2004 grk - added manual identity calculation (removed identity column)
**      3/10/2004 grk - repaired manual identity calculation to include history table
**      7/15/2004 grk - added verification of experiment location aux info
**      11/26/2004 grk - changed type of @comment from text to varchar
**      1/12/2004 grk -- fixed null return on check existing when table is empty
**      10/12/2005 -- grk Added stuff for new work package and proposal fields.
**      2/21/2006  -- grk Added stuff for EUS proposal and user tracking.
**
*****************************************************/
	@reqName varchar(64),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@workPackage varchar(50),
	@msType varchar(20),
	@instrumentSettings varchar(512) = 'na',
	@specialInstructions varchar(512) = 'na',
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(24) = 'na',
	@internalStandard varchar(50) = 'na',
	@comment varchar(244) = 'na',
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@request int output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	
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
	-- Is entry already in database?
	---------------------------------------------------

	declare @requestID int
	set @requestID = 0
	declare @oldEusProposalID varchar(10)
	set @oldEusProposalID = ''
	--
	SELECT 
		@requestID = ISNULL(ID, 0), 
		@oldEusProposalID = RDS_EUS_Proposal_ID
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

	-- cannot create an entry that already exists
	--
	if @requestID <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Requested Dataset "' + @reqName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @requestID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Requested Dataset "' + @reqName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
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

	---------------------------------------------------
	-- verify that dataset type is valid 
	-- and get its id number
	---------------------------------------------------
	declare @datasetTypeID int
	execute @datasetTypeID = GetDatasetTypeID @msType
	if @datasetTypeID = 0
	begin
		print 'Could not find entry in database for dataset type'
		return 51118
	end

	declare @storagePathID int
	set @storagePathID = 0

	---------------------------------------------------
	-- resolve EUS usage type name to ID
	---------------------------------------------------
	declare @eusUsageTypeID int
	set @eusUsageTypeID = 0
	--
	SELECT @eusUsageTypeID = ID
	FROM T_EUS_UsageType
	WHERE  (Name = @eusUsageType)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to resolve EUS usage type: "' + @eusUsageType + '"'
		RAISERROR (@msg, 10, 1)
		return 51072
	end
	--
	if @eusUsageTypeID = 0
	begin
		set @msg = 'Could not resolve EUS usage type: "' + @eusUsageType + '"'
		RAISERROR (@msg, 10, 1)
		return 51073
	end

	---------------------------------------------------
	-- validate EUS proposal and user
	-- if EUS usage type requires them
	---------------------------------------------------
	--
	if @eusUsageType <> 'USER'
		begin
			if @eusProposalID <> '' OR @eusUsersList <> ''
			begin
				set @msg = 'No Proposal ID nor users are to be associated with "' + @eusUsageType + '" usage type'
				RAISERROR (@msg, 10, 1)
				return 51075
			end
			set @eusProposalID = NULL
			set @eusUsersList = ''
		end
	else
		begin			
			---------------------------------------------------
			-- proposal and user list cannot be blank
			---------------------------------------------------
			if @eusProposalID = '' OR @eusUsersList = ''
			begin
				set @msg = 'A Proposal ID and associated users must be selected for "' + @eusUsageType + '" usage type'
				RAISERROR (@msg, 10, 1)
				return 51072
			end

			---------------------------------------------------
			-- verify EUS proposal ID
			---------------------------------------------------
			declare @n int
			set @n = 0
			--
			SELECT @n = count(*)
			FROM T_EUS_Proposals
			WHERE (PROPOSAL_ID = @eusProposalID)	
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error trying to verify EUS proposal ID: "' + @eusProposalID + '"'
				RAISERROR (@msg, 10, 1)
				return 51074
			end
			--
			if @n <> 1
			begin
				set @msg = 'Could not verify EUS proposal ID: "' + @eusProposalID + '"'
				RAISERROR (@msg, 10, 1)
				return 51075
			end

		end

	declare @transName varchar(32)
	set @transName = 'AddUpdateRequestedRun'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
	
		-- Start transaction
		--
		begin transaction @transName
		
		SELECT @request = MAX(M.ID) + 1 FROM
		(
		SELECT ISNULL(MAX(ID), 0) AS ID FROM T_Requested_Run
		UNION
		SELECT ISNULL(MAX(ID), 0) AS ID FROM T_Requested_Run_History
		) M

		INSERT INTO T_Requested_Run
			(
				ID,
				RDS_name, 
				RDS_Oper_PRN, 
				RDS_comment, 
				RDS_created, 
				RDS_instrument_name, 
				RDS_type_ID, 
				RDS_instrument_setting, 
				RDS_special_instructions, 
				RDS_priority, 
				Exp_ID,
				RDS_WorkPackage, 
				RDS_Well_Plate_Num,
				RDS_Well_Num,
				RDS_internal_standard,
				RDS_EUS_Proposal_ID,
				RDS_EUS_UsageType
			) 
			VALUES 
			(
				@request,
				@reqName, 
				@operPRN, 
				@comment, 
				GETDATE(), 
				@instrumentName, 
				@datasetTypeID, 
				@instrumentSettings, 
				@specialInstructions, 
				0, 
				@experimentID,
				@workPackage,
				@wellplateNum,
				@wellNum,
				@internalStandard,
				@eusProposalID,
				@eusUsageTypeID
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
			RDS_special_instructions = @specialInstructions, 
			Exp_ID = @experimentID,
			RDS_WorkPackage = @workPackage, 
			RDS_Well_Plate_Num = @wellplateNum,
			RDS_Well_Num = @wellNum,
			RDS_internal_standard = @internalStandard,
			RDS_EUS_Proposal_ID = @eusProposalID,
			RDS_EUS_UsageType = @eusUsageTypeID
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
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS_User]
GO
