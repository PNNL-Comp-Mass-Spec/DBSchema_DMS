/****** Object:  StoredProcedure [dbo].[AddUpdateRNAPrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateRNAPrepRequest]
/****************************************************
**
**  Desc:   Adds new or edits existing RNA Prep Request
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/19/2014 mem - Initial version
**          05/20/2014 mem - Switched from InstrumentGroup to InstrumentName
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/12/2018 mem - Send @maxLength to AppendToText
**          08/22/2018 mem - Change the EUS User parameter from a varchar(1024) to an integer
**          08/29/2018 mem - Remove parameters @BiomaterialList,  @ProjectNumber, and @NumberOfBiomaterialRepsReceived
**                         - Remove call to DoSamplePrepMaterialOperation
**          02/08/2023 bcg - Update view column name
**
*****************************************************/
(
    @RequestName varchar(128),
    @RequesterPRN varchar(32),
    @Reason varchar(512),
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
    @eusProposalID varchar(10),
    @eusUsageType varchar(50),
    @eusUserID int,                             -- Use Null or 0 if no EUS User ID
    @InstrumentName varchar(128),
    @DatasetType varchar(50),
    @InstrumentAnalysisSpecifications varchar(512),
    @State varchar(32),                         -- New, Open, Prep in Progress, Prep Complete, or Closed
    @ID int output,
    @mode varchar(12) = 'add',                  -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)

    Declare @currentStateID int

    Declare @RequestType varchar(16) = 'RNA'
    Declare @InstrumentGroup varchar(64) = ''

    If IsNull(@eusUserID, 0) <= 0
        Set @eusUserID = Null

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateRNAPrepRequest', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

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
    If NOT (@InstrumentName IN ('', 'none', 'na'))
    Begin
        If IsNull(@DatasetType, '') = ''
            RAISERROR ('Dataset type cannot be empty since the Instrument Name is defined', 11, 118)

        ---------------------------------------------------
        -- Validate the instrument name
        ---------------------------------------------------

        If NOT EXISTS (SELECT * FROM T_Instrument_Name WHERE IN_Name = @InstrumentName)
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

        Declare @datasetTypeID int
        --
        exec @myError = ValidateInstrumentGroupAndDatasetType
                                @DatasetType,
                                @instrumentGroup,
                                @datasetTypeID output,
                                @msg output
        If @myError <> 0
            RAISERROR ('ValidateInstrumentGroupAndDatasetType: %s', 11, 1, @msg)
    End

    ---------------------------------------------------
    -- Resolve campaign ID
    ---------------------------------------------------

    Declare @campaignID int = 0
    --
    execute @campaignID = GetCampaignID @Campaign
    --
    If @campaignID = 0
        RAISERROR('Could not find entry in database for campaignNum "%s"', 11, 14, @Campaign)

    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------

    Declare @organismID int
    execute @organismID = GetOrganismID @Organism
    If @organismID = 0
        RAISERROR ('Could not find entry in database for organismName "%s"', 11, 38, @Organism)

    ---------------------------------------------------
    -- Convert estimated completion date
    ---------------------------------------------------
    Declare @EstimatedCompletionDate datetime

    If @EstimatedCompletion <> ''
    Begin
        Set @EstimatedCompletionDate = CONVERT(datetime, @EstimatedCompletion)
    End

    ---------------------------------------------------
    -- Force values of some properties for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin
        Set @State = 'Pending Approval'
    End

    ---------------------------------------------------
    -- Convert state name to ID
    ---------------------------------------------------

    Declare @StateID int = 0
    --
    SELECT  @StateID = State_ID
    FROM  T_Sample_Prep_Request_State_Name
    WHERE (State_Name = @State)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error trying to resolving state name', 11, 83)
    --
    If @StateID = 0
        RAISERROR ('No entry could be found in database for state "%s"', 11, 23, @State)

    ---------------------------------------------------
    -- Validate EUS type, proposal, and user list
    --
    -- This procedure accepts a list of EUS User IDs,
    -- so we convert to a string before calling it,
    -- then convert back to an integer afterward
    ---------------------------------------------------

    Declare @eusUsageTypeID int
    Declare @eusUsersList varchar(1024) = ''

    If IsNull(@eusUserID, 0) > 0
    Begin
        Set @eusUsersList = Cast(@eusUserID As varchar(12))
        Set @eusUserID = Null
    End

    exec @myError = ValidateEUSUsage
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUsersList output,
                        @eusUsageTypeID output,
                        @msg output
    If @myError <> 0
        RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

    If Len(IsNull(@eusUsersList, '')) > 0
    Begin
        Set @eusUserID = Try_Cast(@eusUsersList As int)

        If IsNull(@eusUserID, 0) <= 0
            Set @eusUserID = Null
    End

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
        Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is deactivated', 0, '; ', 512)
    Else
    Begin
        If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackageNumber And Charge_Code_State = 0)
            Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is likely deactivated', 0, '; ', 512)
    End

    -- Make sure the Work Package is capitalized properly
    --
    SELECT @workPackageNumber = Charge_Code
    FROM T_Charge_Code
    WHERE Charge_Code = @workPackageNumber


    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        Declare @RequestTypeExisting varchar(16)
        Set @currentStateID = 0
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

        -- Changes not allowed if in "closed" state
        --
        If @currentStateID = 5 AND NOT EXISTS (SELECT * FROM V_Operations_Task_Staff_Picklist WHERE username = @callingUser)
            RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

        If @RequestTypeExisting <> @RequestType
            RAISERROR ('Cannot edit requests of type %s with the rna_prep_request page; use http://dms2.pnl.gov/sample_prep_request/report', 11, 7, @RequestTypeExisting)
    End

    If @mode = 'add'
    Begin
        -- name must be unique
        --
        SELECT @myRowCount = count(*)
        FROM T_Sample_Prep_Request
        WHERE (Request_Name = @RequestName)
        --
        SELECT @myError = @@error
        --
        If @myError <> 0 OR @myRowCount> 0
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
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If @Mode = 'add'
    Begin

        INSERT INTO T_Sample_Prep_Request (
            Request_Name,
            Requester_PRN,
            Reason,
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
            EUS_UsageType,
            EUS_Proposal_ID,
            EUS_User_ID,
            Instrument_Analysis_Specifications,
            State,
            Instrument_Group,
            Instrument_Name,
            Dataset_Type,
            Request_Type
        ) VALUES (
            @RequestName,
            @RequesterPRN,
            @Reason,
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
            @eusUsageType,
            @eusProposalID,
            @eusUserID,
            @InstrumentAnalysisSpecifications,
            @StateID,
            @InstrumentGroup,
            @InstrumentName,
            @DatasetType,
            @RequestType
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed:%d', 11, 7, @myError)

        -- Return ID of newly created entry
        --
        Set @ID = SCOPE_IDENTITY()

        -- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @ID, @CallingUser,
                                    @EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

    End -- Add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Sample_Prep_Request
        SET
            Request_Name = @RequestName,
            Requester_PRN = @RequesterPRN,
            Reason = @Reason,
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
            EUS_Proposal_ID = @eusProposalID,
            EUS_UsageType = @eusUsageType,
            EUS_User_ID = @eusUserID,
            Instrument_Analysis_Specifications = @InstrumentAnalysisSpecifications,
            State = @StateID,
            Instrument_Group = @InstrumentGroup,
            Instrument_Name = @InstrumentName,
            Dataset_Type = @DatasetType
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%d"', 11, 4, @ID)

        -- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @ID, @CallingUser,
                                    @EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

    End -- update mode

    End Try
    Begin Catch
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddUpdateRNAPrepRequest'
    End Catch
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRNAPrepRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRNAPrepRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRNAPrepRequest] TO [DMS2_SP_User] AS [dbo]
GO
