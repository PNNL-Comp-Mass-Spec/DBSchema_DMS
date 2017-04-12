/****** Object:  StoredProcedure [dbo].[AddUpdateRNAPrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateRNAPrepRequest
/****************************************************
**
**  Desc: Adds new or edits existing RNA Prep Request
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	mem
**	Date:	05/19/2014 mem - Initial version
**			05/20/2014 mem - Switched from InstrumentGroup to InstrumentName
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**    
*****************************************************/
(
	@RequestName varchar(128),
 	@RequesterPRN varchar(32),
	@Reason varchar(512),
	@BiomaterialList varchar(1024),
	@Organism varchar(128),
	@BiohazardLevel varchar(12),
	@Campaign varchar(128),
	@NumberofSamples int,
	@SampleNameList varchar(1500),
	@SampleType varchar(128),
	@PrepMethod varchar(512),
	@SampleNamingConvention varchar(128),
	@EstimatedCompletion varchar(32),
	@WorkPackageNumber varchar(64),
	@ProjectNumber varchar(15),
	@eusProposalID varchar(10),
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024),
	@InstrumentName varchar(128),
	@DatasetType varchar(50),
	@InstrumentAnalysisSpecifications varchar(512),
	@State varchar(32),
	@ID int output,
	@NumberOfBiomaterialRepsReceived int,
	@mode varchar(12) = 'add',				-- 'add' or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

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

	Declare @RequestType varchar(16) = 'RNA'
	Declare @InstrumentGroup varchar(64) = ''

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	--
	Set @InstrumentName = IsNull(@InstrumentName, '')
	
	Set @DatasetType = IsNull(@DatasetType, '')
 
	---------------------------------------------------
	-- Validate dataset type
	---------------------------------------------------
	--
	IF NOT (@InstrumentName IN ('', 'none', 'na'))
	begin
		If IsNull(@DatasetType, '') = ''
			RAISERROR ('Dataset type cannot be empty since the Instrument Name is defined', 11, 118)
	
		---------------------------------------------------
		-- Validate the instrument name
		---------------------------------------------------
				
		IF NOT EXISTS (SELECT * FROM T_Instrument_Name WHERE IN_Name = @InstrumentName)
		Begin
			-- Check whether @InstrumentName actually has an instrument group
			--
			SELECT TOP 1 @InstrumentName = IN_name
			FROM T_Instrument_Name
			WHERE IN_Group = @InstrumentName AND
			      IN_Status <> 'inactive'
		End

		---------------------------------------------------
		-- Determine the Instrument Group
		---------------------------------------------------
		
		SELECT TOP 1 @InstrumentGroup = IN_Group
		FROM T_Instrument_Name
		WHERE IN_Name = @InstrumentName

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
	-- Resolve biomaterial (cell cultures)
	---------------------------------------------------

	-- Create tempoary table to hold biomaterial names as input
	--
	create table #Tmp_BioMaterial (
		name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not create temporary table for biomaterial list', 11, 78)

	-- get biomaterial names from list argument into table
	--
	INSERT INTO #Tmp_BioMaterial (name) 
	SELECT item FROM MakeTableFromListDelim(@BiomaterialList, ';')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Could not populate temporary table for biomaterial list', 11, 79)

	-- verify that biomaterial items exist
	--
	declare @cnt int
	set @cnt = -1
	SELECT @cnt = count(*) 
	FROM #Tmp_BioMaterial 
	WHERE [name] not in (
		SELECT CC_Name
		FROM	T_Cell_Culture
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Was not able to check for biomaterial in database', 11, 80)
	--
	if @cnt <> 0 
		RAISERROR ('One or more biomaterial items was not in database', 11, 81)

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
	-- Is entry already in database?
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		Declare @tmp int = 0
		Declare @RequestTypeExisting varchar(16)
		set @currentStateID = 0		
		--
		SELECT 
			@tmp = ID, 
			@RequestTypeExisting = Request_Type,
			@currentStateID = State
		FROM  T_Sample_Prep_Request
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 7)

		-- changes not allowed if in "closed" state
		--
		If @currentStateID = 5 AND NOT EXISTS (SELECT * FROM V_Operations_Task_Staff_Picklist WHERE PRN = @callingUser)
			RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

		If @RequestTypeExisting <> @RequestType
			RAISERROR ('Cannot edit requests of type %s with the rna_prep_request page; use http://dms2.pnl.gov/sample_prep_request/report', 11, 7, @RequestTypeExisting)
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
			RAISERROR ('Cannot use inactive Work Package "%s" for a new RNA prep request', 11, 8, @WorkPackageNumber)
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
			Sample_Naming_Convention, 
			Estimated_Completion,
			Work_Package_Number, 
			Project_Number,
			EUS_UsageType, 
			EUS_Proposal_ID, 
			EUS_User_List,
			Instrument_Analysis_Specifications, 
			State, 
			Instrument_Group,
			Instrument_Name, 
			Dataset_Type,
			Number_Of_Biomaterial_Reps_Received,
			Request_Type					
		) VALUES (
			@RequestName, 
			@RequesterPRN, 
			@Reason,
			@BiomaterialList, 
			@Organism,
			@BiohazardLevel,
			@Campaign, 
			@NumberofSamples, 
			@SampleNameList, 
			@SampleType, 
			@PrepMethod, 
			@SampleNamingConvention, 
			@EstimatedCompletionDate,
			@WorkPackageNumber, 
			@ProjectNumber,
			@eusUsageType,
			@eusProposalID,
			@eusUsersList,
			@InstrumentAnalysisSpecifications, 
			@StateID,
			@InstrumentGroup,
			@InstrumentName,
			@DatasetType,
			@NumberOfBiomaterialRepsReceived,
			@RequestType					
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
			Cell_Culture_List = @BiomaterialList, 
			Organism = @Organism, 
			Biohazard_Level = @BiohazardLevel, 
			Campaign = @Campaign, 
			Number_of_Samples = @NumberofSamples, 
			Sample_Name_List = @SampleNameList, 
			Sample_Type = @SampleType, 
			Prep_Method = @PrepMethod, 
			Sample_Naming_Convention = @SampleNamingConvention, 
			Estimated_Completion = @EstimatedCompletionDate,
			Work_Package_Number = @WorkPackageNumber, 
			Project_Number = @ProjectNumber,
			EUS_Proposal_ID = @eusProposalID,
			EUS_UsageType = @eusUsageType,
			EUS_User_List = @eusUsersList,
			Instrument_Analysis_Specifications = @InstrumentAnalysisSpecifications, 
			State = @StateID,
			Instrument_Group = @InstrumentGroup,
			Instrument_Name = @InstrumentName, 
			Dataset_Type = @DatasetType,
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
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateRNAPrepRequest'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRNAPrepRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRNAPrepRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRNAPrepRequest] TO [DMS2_SP_User] AS [dbo]
GO
