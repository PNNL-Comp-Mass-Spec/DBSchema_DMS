/****** Object:  StoredProcedure [dbo].[AddUpdateSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateSamplePrepRequest]
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
**			04/14/2010 grk - widened @CellCultureList field
**			04/22/2010 grk - try-catch for error handling
**			08/09/2010 grk - added handling for 'Closed (containers and material)'
**			08/15/2010 grk - widened @CellCultureList field
**			08/27/2010 mem - Now auto-switching @instrumentName to be instrument group instead of instrument name
**			08/15/2011 grk - added Separation_Type
**			12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**			10/19/2012 mem - Now auto-changing @SeparationType to Separation_Group if @SeparationType specifies a separation type
**			04/05/2013 mem - Now requiring that @EstimatedMSRuns be defined.  If it is non-zero, then instrument group, dataset type, and separation group must also be defined
**			04/08/2013 grk - Added @BlockAndRandomizeSamples, @BlockAndRandomizeRuns,and @IOPSPermitsCurrent
**			04/09/2013 grk - disregarding internal standards
**			04/09/2013 grk - chaged priority to text "Normal/High", added @NumberOfBiomaterialRepsReceived, removed Facility field
**			04/09/2013 mem - Renamed parameter @InstrumentName to @InstrumentGroup
**			               - Renamed parameter @SeparationType to @SeparationGroup
**			05/02/2013 mem - Now validating that fields @BlockAndRandomizeSamples, @BlockAndRandomizeRuns, and @IOPSPermitsCurrent are 'Yes', 'No', '', or Null
**			06/05/2013 mem - Now validating @WorkPackageNumber against T_Charge_Code
**			06/06/2013 mem - Now showing warning if the work package is deactivated
**			01/23/2014 mem - Now requiring that the work package be active when creating a new sample prep requeset
**			03/13/2014 grk - Added ability to edit closed SPR for staff with permissions (OMCDA-1071)
**			05/19/2014 mem - Now populating Request_Type
**			05/20/2014 mem - Now storing InstrumentGroup in column Instrument_Group instead of Instrument_Name
**			03/13/2014 grk - Added material container field (OMCDA-1076)
**    
*****************************************************/
(
	@RequestName varchar(128),
	@RequesterPRN varchar(32),
	@Reason varchar(512),
	@CellCultureList varchar(1024),
	@MaterialContainerList VARCHAR(2048),
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
	@instrumentGroup varchar(128),				-- Will typically contain an instrument group name; could also contain "None" or any other text
	@DatasetType varchar(50),
	@InstrumentAnalysisSpecifications varchar(512),
	@Comment varchar(1024),
	@Priority varchar(12),
	@State varchar(32),
	@UseSingleLCColumn varchar(50),
	@ID int output,
	@SeparationGroup varchar(256),			-- Separation group	
	@BlockAndRandomizeSamples char(3),		-- 'Yes', 'No', or 'NA'
	@BlockAndRandomizeRuns char(3),			-- 'Yes' or 'No'
	@IOPSPermitsCurrent char(3),			-- 'Yes' or 'No'
	@ReasonForHighPriority varchar(1024),
	@NumberOfBiomaterialRepsReceived int,
	@mode varchar(12) = 'add',				-- 'add' or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
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

	Declare @RequestType varchar(16) = 'Default'
	
	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	--
	Set @InstrumentGroup = IsNull(@InstrumentGroup, '')
	
	Set @DatasetType = IsNull(@DatasetType, '')
 
	Set @TechnicalReplicates = IsNull(@TechnicalReplicates, '')
 
	If Len(IsNull(@EstimatedMSRuns, '')) < 1
		RAISERROR ('Estimated number of MS runs was blank; it should be 0 or a positive number', 11, 116)

	If IsNull(@BlockAndRandomizeSamples, '') NOT IN ('', 'Yes', 'No', 'NA')
		RAISERROR ('Field BlockAndRandomizeSamples should be Yes, No, or NA', 11, 116)
	
	If IsNull(@BlockAndRandomizeRuns, '') NOT IN ('', 'Yes', 'No')
		RAISERROR ('Field BlockAndRandomizeRuns should be Yes or No', 11, 116)

	If IsNull(@IOPSPermitsCurrent, '') NOT IN ('', 'Yes', 'No')
		RAISERROR ('Field IOPSPermitsCurrent should be Yes or No', 11, 116)
				
	---------------------------------------------------
	-- validate priority
	---------------------------------------------------

	IF @Priority <> 'Normal' AND ISNULL(@ReasonForHighPriority, '') = ''
		RAISERROR ('Priority "%s" requires justification reason to be provided', 11, 37, @Priority)
		
	---------------------------------------------------
	-- Validate instrument group and dataset type
	---------------------------------------------------
	--
	IF NOT (@EstimatedMSRuns IN ('0', 'None'))
	begin
		If @InstrumentGroup IN ('none', 'na')
			RAISERROR ('Estimated runs must be 0 or "none" when instrument group is: %s', 11, 1, @InstrumentGroup)
		
		If ISNUMERIC(@EstimatedMSRuns) = 0
			RAISERROR ('Estimated runs must be an integer or "none"', 11, 116)
		
		If IsNull(@InstrumentGroup, '') = ''
			RAISERROR ('Instrument group cannot be empty since the estimated MS run count is non-zero', 11, 117)

		If IsNull(@DatasetType, '') = ''
			RAISERROR ('Dataset type cannot be empty since the estimated MS run count is non-zero', 11, 118)

		If IsNull(@SeparationGroup, '') = ''
			RAISERROR ('Separation group cannot be empty since the estimated MS run count is non-zero', 11, 119)

		If IsNull(@TechnicalReplicates, '') = ''
			RAISERROR ('Technical Replicate count cannot be empty since the estimated MS run count is non-zero; enter "none" if no replicates', 11, 120)
		
		---------------------------------------------------
		-- Determine the Instrument Group
		---------------------------------------------------
				
		IF NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @InstrumentGroup)
		Begin
			-- Try to update instrument group using T_Instrument_Name
			SELECT @InstrumentGroup = IN_Group
			FROM T_Instrument_Name
			WHERE IN_Name = @InstrumentGroup AND
			      IN_Status <> 'inactive'

		End

		---------------------------------------------------
		-- validate instrument group and dataset type
		---------------------------------------------------
		
		declare @datasetTypeID int
		--
		exec @myError = ValidateInstrumentGroupAndDatasetType
								@DatasetType,
								@instrumentGroup,
								@datasetTypeID output,
								@msg output 
		if @myError <> 0
			RAISERROR ('ValidateInstrumentGroupAndDatasetType: %s', 11, 1, @msg)
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
	-- Resolve material containers
	---------------------------------------------------

	-- create tempoary table to hold names of material containers as input
	--
	create table #MC (
		name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not create temporary table for material container list', 11, 50)

	-- get names of material containers from list argument into table
	--
	INSERT INTO #MC (name) 
	SELECT item FROM MakeTableFromList(@MaterialContainerList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not populate temporary table for material container list', 11, 51)

	-- verify that material containers exist
	--
	set @cnt = -1
	SELECT @cnt = count(*) 
	FROM #MC 
	WHERE [name] not in (
		SELECT Tag
		FROM T_Material_Containers
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Was not able to check for material containers in database', 11, 52)
	--
	if @cnt <> 0 
		RAISERROR ('One or more material containers was not in database', 11, 53)

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
	-- validate EUS type, proposal, and user list
	---------------------------------------------------
	declare @eusUsageTypeID int
	exec @myError = ValidateEUSUsage
						@eusUsageType output,
						@eusProposalID output,
						@eusUsersList output,
						@eusUsageTypeID output,
						@msg output
	if @myError <> 0
		RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

	---------------------------------------------------
	-- Validate the work package
	---------------------------------------------------

	Declare @allowNoneWP tinyint = 0
	
	exec @myError = ValidateWP
						@workPackageNumber,
						@allowNoneWP,
						@msg output

	If @myError <> 0
		RAISERROR ('ValidateWP: %s', 11, 1, @msg)

	If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackageNumber And Deactivated = 'Y')	   
		Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is deactivated', 0, '; ')
	Else
	Begin
		If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackageNumber And Charge_Code_State = 0)
			Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is likely deactivated', 0, '; ')
	End
		
	---------------------------------------------------
	-- Auto-change separation type to separation group, if applicable
	---------------------------------------------------
	--	
	If Not Exists (SELECT * FROM T_Separation_Group WHERE Sep_Group = @SeparationGroup)
	Begin
		Declare @SeparationGroupAlt varchar(64) = ''
		
		SELECT @SeparationGroupAlt = Sep_Group
		FROM T_Secondary_Sep
		WHERE SS_Name = @SeparationGroup AND
		      SS_Active = 1
		
		If IsNull(@SeparationGroupAlt, '') <> ''
			Set @SeparationGroup = @SeparationGroupAlt
	End
	
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		Declare @tmp int = 0
		Declare @currentAssignedPersonnel VARCHAR(256)
		Declare @RequestTypeExisting varchar(16)
		set @currentStateID = 0
		--
		SELECT 
			@tmp = ID, 
			@currentStateID = State, 
			@currentAssignedPersonnel = Assigned_Personnel,
			@RequestTypeExisting = Request_Type
		FROM  T_Sample_Prep_Request
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 7)

		-- changes not allowed if in "closed" state
		--
		if @currentStateID = 5 AND NOT EXISTS (SELECT * FROM V_Operations_Task_Staff_Picklist WHERE PRN = @callingUser)
			RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

		-- don't allow change to "Prep in Progress" 
		-- unless someone has been assigned @AssignedPersonnel @currentAssignedPersonnel
		If @State = 'Prep in Progress' AND ((@AssignedPersonnel = '') OR (@AssignedPersonnel = 'na'))
			RAISERROR ('State cannot be changed to "Prep in Progress" unless someone has been assigned', 11, 84)
	
		If @RequestTypeExisting <> @RequestType
			RAISERROR ('Cannot edit requests of type %s with the sample_prep_request page; use http://dms2.pnl.gov/rna_prep_request/report', 11, 7, @RequestTypeExisting)
			
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
			
		-- Make sure the work package number is not inactive
		--
		Declare @ActivationState tinyint = 10
		Declare @ActivationStateName varchar(128)
		
		SELECT @ActivationState = CCAS.Activation_State,
		       @ActivationStateName = CCAS.Activation_State_Name
		FROM T_Charge_Code CC
		     INNER JOIN T_Charge_Code_Activation_State CCAS
		       ON CC.Activation_State = CCAS.Activation_State
		WHERE (CC.Charge_Code = @WorkPackageNumber)

		If @ActivationState >= 3
			RAISERROR ('Cannot use inactive Work Package "%s" for a new sample prep request', 11, 8, @WorkPackageNumber)
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
			State, 
			Instrument_Group, 
			Dataset_Type,
			Technical_Replicates,
			Separation_Type,
			BlockAndRandomizeSamples,
			BlockAndRandomizeRuns,
			IOPSPermitsCurrent,
			Reason_For_High_Priority,
			Number_Of_Biomaterial_Reps_Received,
			Request_Type,
			Material_Container_List	
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
			@StateID,
			@instrumentGroup,
			@DatasetType,
			@TechnicalReplicates,
			@SeparationGroup,
			@BlockAndRandomizeSamples,
			@BlockAndRandomizeRuns,
			@IOPSPermitsCurrent,
			@ReasonForHighPriority,
			@NumberOfBiomaterialRepsReceived,
			@RequestType,
			@MaterialContainerList
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
			Material_Container_List = @MaterialContainerList,
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
			State = @StateID,
			Instrument_Group = @instrumentGroup, 
			Instrument_Name = Null,
			Dataset_Type = @DatasetType,
			Technical_Replicates = @TechnicalReplicates,
			Separation_Type = @SeparationGroup,
			BlockAndRandomizeSamples = @BlockAndRandomizeSamples,
			BlockAndRandomizeRuns = @BlockAndRandomizeRuns,
			IOPSPermitsCurrent = @IOPSPermitsCurrent,
			Reason_For_High_Priority = @ReasonForHighPriority,
			Number_Of_Biomaterial_Reps_Received = @NumberOfBiomaterialRepsReceived 
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
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [PNL\D3M580] AS [dbo]
GO
