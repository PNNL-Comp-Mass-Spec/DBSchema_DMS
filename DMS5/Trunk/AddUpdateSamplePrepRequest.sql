/****** Object:  StoredProcedure [dbo].[AddUpdateSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateSamplePrepRequest
/****************************************************
**
**  Desc: Adds new or edits existing SamplePrepRequest
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	06/09/2005
**			06/10/2005 grk - added Reason argument
**			06/16/2005 grk - added state restriction for update
**			07/26/2005 grk - added stuff for requested personnel
**			08/09/2005 grk - widened @SampleNameList
**			10/12/2005 grk - added @UseSingleLCColumn
**			10/26/2005 grk - disallowed change if not in 'New" state
**			10/28/2005 grk - added handling for internal standard
**			11/01/2005 grk - rescinded disallowed change in 'New' state
**			11/11/2005 grk - added handling for postdigest internal standard
**			01/03/2006 grk - added check for existing request name
**			03/14/2006 grk - added stuff for multiple assigned users
**			08/10/2006 grk - modified state handling
**			08/10/2006 grk - allowed multiple requested personnel users
**			12/15/2006 grk - added EstimatedMSRuns argument (Ticket #336)
**			04/20/2007 grk - added validation for organism, campaign, cell culture (Ticket #440)
**			07/11/2007 grk - added "standard" EUS fields and removed old proposal field(Ticket #499)
**			07/30/2007 grk - corrected error in update of EUS fields (Ticket #499)
**			09/01/2007 grk - added instrument name and datasets type fields (Ticket #512)
**			09/04/2007 grk - added @TechnicalReplicates fields (Ticket #512)
**			05/02/2008 grk - repaired leaking query and arranged for default add state to be "Pending Approval"
**			05/16/2008 mem - Added optional parameter @callingUser; if provided, then will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**			12/02/2009 grk - don't allow change to "Prep in Progress" unless someone has been assigned
**			03/11/2010- grk - added Facility field
**			04/14/2010- grk - widened @CellCultureList field
**			04/22/2010 grk - try-catch for error handling
**			08/09/2010 grk - added handling for 'Closed (containers and material)'
**    
*****************************************************/
(
	@RequestName varchar(128),
	@RequesterPRN varchar(32),
	@Reason varchar(512),
	@CellCultureList varchar(512),
	@Organism varchar(128),
	@BiohazardLevel varchar(12),
	@Campaign varchar(128),
	@NumberofSamples int,
	@SampleNameList varchar(1500),
	@SampleType varchar(128),
	@PrepMethod varchar(512),
	@PrepByRobot varchar(8),
	@SpecialInstructions varchar(1024),
	@SampleNamingConvention varchar(128),
	@AssignedPersonnel varchar(256),
	@RequestedPersonnel varchar(256),
	@EstimatedCompletion varchar(32),
	@EstimatedMSRuns varchar(16),
	@WorkPackageNumber varchar(64),
	@ProjectNumber varchar(15),
	@eusProposalID varchar(10),
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024),
	@ReplicatesofSamples varchar(512),  
	@TechnicalReplicates varchar(64),
	@InstrumentName varchar(128),
	@DatasetType varchar(50),
	@InstrumentAnalysisSpecifications varchar(512),
	@Comment varchar(1024),
	@Priority tinyint,
	@State varchar(32),
	@UseSingleLCColumn varchar(50),
	@internalStandard varchar(50),
	@postdigestIntStd varchar(50),
	@Facility VARCHAR(32),
	@ID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	DECLARE @msg varchar(512) 

	declare @currentStateID int
	
	DECLARE @retireMaterial INT
	IF @State = 'Closed (containers and material)'
	BEGIN
		SET @retireMaterial = 1
		SET @State = 'Closed'
	END
	ELSE 
		SET @retireMaterial = 0

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	--
	if LEN(@instrumentName) < 1
		RAISERROR ('Instrument name was blank', 11, 114)
	--
	if LEN(@DatasetType) < 1
		RAISERROR ('Dataset type was blank', 11, 115)
 
	---------------------------------------------------
	-- validate instrument name and dataset type
	---------------------------------------------------
	if NOT (@EstimatedMSRuns = '0' or @EstimatedMSRuns = 'None')
	begin
		declare @instrumentID int
		declare @datasetTypeID int
		--
		exec @myError = ValidateInstrumentAndDatasetType
								@DatasetType,
								@instrumentName,
								@instrumentID output,
								@datasetTypeID output,
								@msg output 
		if @myError <> 0
			RAISERROR ('ValidateInstrumentAndDatasetType:%s', 11, 1, @msg)
	end					
							
	---------------------------------------------------
	-- Resolve campaign ID
	---------------------------------------------------

	declare @campaignID int
	SET @campaignID = 0
	--
	execute @campaignID = GetCampaignID @Campaign
	--
	if @campaignID = 0
		RAISERROR('Could not find entry in database for campaignNum "%s"', 11, 14, @Campaign)

	---------------------------------------------------
	-- Resolve cell cultures
	---------------------------------------------------

	-- create tempoary table to hold names of cell cultures as input
	--
	create table #CC (
		name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not create temporary table for cell culture list', 11, 78)

	-- get names of cell cultures from list argument into table
	--
	INSERT INTO #CC (name) 
	SELECT item FROM MakeTableFromListDelim(@cellCultureList, ';')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not populate temporary table for cell culture list', 11, 79)

	-- verify that cell cultures exist
	--
	declare @cnt int
	set @cnt = -1
	SELECT @cnt = count(*) 
	FROM #CC 
	WHERE [name] not in (
		SELECT CC_Name
		FROM	T_Cell_Culture
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Was not able to check for cell cultures in database', 11, 80)
	--
	if @cnt <> 0 
		RAISERROR ('One or more cell cultures was not in database', 11, 81)

	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @Organism
	if @organismID = 0
		RAISERROR ('Could not find entry in database for organismName "%s"', 11, 38, @Organism)

	---------------------------------------------------
	-- convert estimated completion date
	---------------------------------------------------
	declare @EstimatedCompletionDate datetime

	if @EstimatedCompletion <> ''
	begin
		set @EstimatedCompletionDate = CONVERT(datetime, @EstimatedCompletion)
	end
  
	---------------------------------------------------
	-- force values of some properties for add mode
	---------------------------------------------------
  
	if @mode = 'add'
	begin
		set @State = 'Pending Approval'
		set @AssignedPersonnel = 'na'
	end

	---------------------------------------------------
	-- Convert state name to ID
	---------------------------------------------------
	declare @StateID int
	set @StateID = 0
	--
	SELECT  @StateID = State_ID
	FROM  T_Sample_Prep_Request_State_Name
	WHERE (State_Name = @State)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
      RAISERROR ('Error trying to resolving state name', 11, 83)
    --
    if @StateID = 0
		RAISERROR ('No entry could be found in database for state "%s"', 11, 23, @State)
    
 	---------------------------------------------------
	-- Resolve internal standard ID
	---------------------------------------------------

	declare @internalStandardID int
	set @internalStandardID = 0
	--
	SELECT @internalStandardID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @internalStandard)
	--
	if @internalStandardID = 0
		RAISERROR ('Could not find entry in database for predigestion internal standard "%s"', 11, 9, @internalStandard)

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	declare @postdigestIntStdID int
	set @postdigestIntStdID = 0
	--
	SELECT @postdigestIntStdID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @postdigestIntStd)
	--
	if @postdigestIntStdID = 0
		RAISERROR ('Could not find entry in database for postdigestion internal standard "%s"', 11, 10, @postdigestIntStdID)

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
		RAISERROR ('ValidateEUSUsage:%s', 11, 1, @msg)

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		set @currentStateID = 0
		DECLARE @currentAssignedPersonnel VARCHAR(256)
		--
		SELECT 
			@tmp = ID, 
			@currentStateID = State, 
			@currentAssignedPersonnel = Assigned_Personnel
		FROM  T_Sample_Prep_Request
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 7)

		-- changes not allowed if in "closed" state
		--
		if @currentStateID = 5
			RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

		-- don't allow change to "Prep in Progress" 
		-- unless someone has been assigned @AssignedPersonnel @currentAssignedPersonnel
		IF @State = 'Prep in Progress' AND ((@AssignedPersonnel = '') OR (@AssignedPersonnel = 'na'))
			RAISERROR ('State cannot be changed to "Prep in Progress" unless someone has been assigned', 11, 84)
	end

	if @mode = 'add'
	begin
		-- name must be unique
		--
		SELECT @myRowCount = count(*)
		FROM T_Sample_Prep_Request
		WHERE (Request_Name = @RequestName)
		--
		SELECT @myError = @@error
		--
		if @myError <> 0 OR @myRowCount> 0
			RAISERROR ('Cannot add: Request "%s" already in database', 11, 8, @RequestName)
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
			
		INSERT INTO T_Sample_Prep_Request (
			Request_Name, 
			Requester_PRN, 
			Reason,
			Cell_Culture_List, 
			Organism, 
			Biohazard_Level, 
			Campaign, 
			Number_of_Samples, 
			Sample_Name_List, 
			Sample_Type, 
			Prep_Method, 
			Prep_By_Robot, 
			Special_Instructions, 
			Sample_Naming_Convention, 
			Requested_Personnel,
			Assigned_Personnel, 
			Estimated_Completion,
			Estimated_MS_runs,
			Work_Package_Number, 
			Project_Number,
			EUS_UsageType, 
			EUS_Proposal_ID, 
			EUS_User_List,
			Replicates_of_Samples, 
			Instrument_Analysis_Specifications, 
			Comment, 
			Priority, 
			UseSingleLCColumn,
			Internal_standard_ID, 
			Postdigest_internal_std_ID,
			State, 
			Instrument_Name, 
			Dataset_Type,
			Technical_Replicates,
			Facility
		) VALUES (
			@RequestName, 
			@RequesterPRN, 
			@Reason,
			@CellCultureList, 
			@Organism, 
			@BiohazardLevel, 
			@Campaign, 
			@NumberofSamples, 
			@SampleNameList, 
			@SampleType, 
			@PrepMethod, 
			@PrepByRobot, 
			@SpecialInstructions, 
			@SampleNamingConvention, 
			@RequestedPersonnel,
			@AssignedPersonnel, 
			@EstimatedCompletionDate,
			@EstimatedMSRuns,
			@WorkPackageNumber, 
			@ProjectNumber,
			@eusUsageType,
			@eusProposalID,
			@eusUsersList,
			@ReplicatesofSamples, 
			@InstrumentAnalysisSpecifications, 
			@Comment, 
			@Priority, 
			@UseSingleLCColumn,
			@InternalstandardID, 
			@postdigestIntStdID,
			@StateID,
			@InstrumentName,
			@DatasetType,
			@TechnicalReplicates,
			@Facility
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed:%d', 11, 7, @myError)

		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Sample_Prep_Request')

		-- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @ID, @CallingUser, 
									@EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	if @Mode = 'update' AND @retireMaterial = 1
	BEGIN
		EXEC @myError = DoSamplePrepMaterialOperation
							@ID,
							'retire_all',
							@message output,
							@callingUser
		if @myError <> 0
			RAISERROR ('DoSamplePrepMaterialOperation failed:%d, %s', 11, 7, @myError, @message)
	END 
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Sample_Prep_Request 
		SET 
			Request_Name = @RequestName, 
			Requester_PRN = @RequesterPRN, 
			Reason = @Reason,
			Cell_Culture_List = @CellCultureList, 
			Organism = @Organism, 
			Biohazard_Level = @BiohazardLevel, 
			Campaign = @Campaign, 
			Number_of_Samples = @NumberofSamples, 
			Sample_Name_List = @SampleNameList, 
			Sample_Type = @SampleType, 
			Prep_Method = @PrepMethod, 
			Prep_By_Robot = @PrepByRobot, 
			Special_Instructions = @SpecialInstructions, 
			Sample_Naming_Convention = @SampleNamingConvention, 
			Requested_Personnel = @RequestedPersonnel,
			Assigned_Personnel = @AssignedPersonnel, 
			Estimated_Completion = @EstimatedCompletionDate,
			Estimated_MS_runs = @EstimatedMSRuns,
			Work_Package_Number = @WorkPackageNumber, 
			Project_Number = @ProjectNumber,
			EUS_Proposal_ID = @eusProposalID,
			EUS_UsageType = @eusUsageType,
			EUS_User_List = @eusUsersList,
			Replicates_of_Samples = @ReplicatesofSamples, 
			Instrument_Analysis_Specifications = @InstrumentAnalysisSpecifications, 
			Comment = @Comment, 
			Priority = @Priority, 
			UseSingleLCColumn = @UseSingleLCColumn,
			Internal_standard_ID = @InternalstandardID, 
			Postdigest_internal_std_ID = @postdigestIntStdID,
			State = @StateID,
			Instrument_Name = @InstrumentName, 
			Dataset_Type = @DatasetType,
			Technical_Replicates = @TechnicalReplicates,
			Facility = @Facility
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%d"', 11, 4, @ID)

		-- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @ID, @CallingUser, 
									@EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateSamplePrepRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSamplePrepRequest] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [PNL\D3M580] AS [dbo]
GO
