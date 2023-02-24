/****** Object:  StoredProcedure [dbo].[AddUpdateSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateSamplePrepRequest]
/****************************************************
**
**  Desc:
**      Adds new or edits existing Sample Prep Request
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/09/2005
**          06/10/2005 grk - added Reason argument
**          06/16/2005 grk - added state restriction for update
**          07/26/2005 grk - added stuff for requested personnel
**          08/09/2005 grk - widened @sampleNameList
**          10/12/2005 grk - added @useSingleLCColumn
**          10/26/2005 grk - disallowed change if not in 'New" state
**          10/28/2005 grk - added handling for internal standard
**          11/01/2005 grk - rescinded disallowed change in 'New' state
**          11/11/2005 grk - added handling for postdigest internal standard
**          01/03/2006 grk - added check for existing request name
**          03/14/2006 grk - added stuff for multiple assigned users
**          08/10/2006 grk - modified state handling
**          08/10/2006 grk - allowed multiple requested personnel users
**          12/15/2006 grk - added EstimatedMSRuns argument (Ticket #336)
**          04/20/2007 grk - added validation for organism, campaign, cell culture (Ticket #440)
**          07/11/2007 grk - added "standard" EUS fields and removed old proposal field(Ticket #499)
**          07/30/2007 grk - corrected error in update of EUS fields (Ticket #499)
**          09/01/2007 grk - added instrument name and datasets type fields (Ticket #512)
**          09/04/2007 grk - added @technicalReplicates fields (Ticket #512)
**          05/02/2008 grk - repaired leaking query and arranged for default add state to be "Pending Approval"
**          05/16/2008 mem - Added optional parameter @callingUser; if provided, then will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          12/02/2009 grk - don't allow change to "Prep in Progress" unless someone has been assigned
**          04/14/2010 grk - widened @cellCultureList field
**          04/22/2010 grk - try-catch for error handling
**          08/09/2010 grk - added handling for 'Closed (containers and material)'
**          08/15/2010 grk - widened @cellCultureList field
**          08/27/2010 mem - Now auto-switching @instrumentName to be instrument group instead of instrument name
**          08/15/2011 grk - added Separation_Type
**          12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**          10/19/2012 mem - Now auto-changing @separationType to Separation_Group if @separationType specifies a separation type
**          04/05/2013 mem - Now requiring that @estimatedMSRuns be defined.  If it is non-zero, then instrument group, dataset type, and separation group must also be defined
**          04/08/2013 grk - Added @blockAndRandomizeSamples, @blockAndRandomizeRuns, and @iOPSPermitsCurrent
**          04/09/2013 grk - disregarding internal standards
**          04/09/2013 grk - changed priority to text "Normal/High", added @numberOfBiomaterialRepsReceived, removed Facility field
**          04/09/2013 mem - Renamed parameter @instrumentName to @instrumentGroup
**                         - Renamed parameter @separationType to @separationGroup
**          05/02/2013 mem - Now validating that fields @blockAndRandomizeSamples, @blockAndRandomizeRuns, and @iOPSPermitsCurrent are 'Yes', 'No', '', or Null
**          06/05/2013 mem - Now validating @workPackageNumber against T_Charge_Code
**          06/06/2013 mem - Now showing warning if the work package is deactivated
**          01/23/2014 mem - Now requiring that the work package be active when creating a new sample prep requeset
**          03/13/2014 grk - Added ability to edit closed SPR for staff with permissions (OMCDA-1071)
**          05/19/2014 mem - Now populating Request_Type
**          05/20/2014 mem - Now storing InstrumentGroup in column Instrument_Group instead of Instrument_Name
**          03/13/2014 grk - Added material container field (OMCDA-1076)
**          05/29/2015 mem - Now validating that @estimatedCompletionDate is today or later
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/12/2017 mem - Remove 9 deprecated parameters:
**                             @cellCultureList, @numberOfBiomaterialRepsReceived, @replicatesofSamples, @prepByRobot,
**                             @technicalReplicates, @specialInstructions, @useSingleLCColumn, @projectNumber, and @iOPSPermitsCurrent
**                         - Change the default state from 'Pending Approval' to 'New'
**                         - Validate list of Requested Personnel and Assigned Personnel
**                         - Expand @comment to varchar(2048)
**          06/13/2017 mem - Validate @priority
**                         - Check for name collisions when @mode is update
**                         - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/25/2017 mem - Add parameter @tissue (tissue name, e.g. hypodermis)
**          09/01/2017 mem - Allow @tissue to be a BTO ID (e.g. BTO:0000131)
**          06/12/2018 mem - Send @maxLength to AppendToText
**          08/22/2018 mem - Change the EUS User parameter from a varchar(1024) to an integer
**          08/29/2018 mem - Remove call to DoSamplePrepMaterialOperation since we stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
**          11/30/2018 mem - Make @reason an input/output parameter
**          01/23/2019 mem - Switch @reason back to a normal input parameter since view V_Sample_Prep_Request_Entry now appends the __NoCopy__ flag to several fields
**          01/13/2020 mem - Require @requestedPersonnel to include a sample prep staff member (no longer allow 'na' or 'any')
**          08/12/2020 mem - Check for ValidateEUSUsage returning a message, even if it returns 0
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          05/25/2021 mem - Set @samplePrepRequest to 1 when calling ValidateEUSUsage
**          05/26/2021 mem - Override @eusUsageType if @mode is 'add' and the campaign has EUSUsageType = 'USER_REMOTE
**          05/27/2021 mem - Refactor EUS Usage validation code into ValidateEUSUsage
**          06/10/2021 mem - Add parameters @estimatedPrepTimeDays and @stateComment
**          06/11/2021 mem - Auto-remove 'na' from @assignedPersonnel
**          10/11/2021 mem - Clear @stateComment when @state is 'Closed'
**                         - Only allow sample prep staff to update estimated prep time
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/03/2021 mem - Clear @stateComment when creating a new prep request
**          03/21/2022 mem - Refactor personnel validation code into ValidateRequestUsers
**          04/11/2022 mem - Check for whitespace in @requestName
**          04/18/2022 mem - Replace tabs in prep request names with spaces
**          08/08/2022 mem - Update StateChanged when the state changes
**          08/25/2022 mem - Use view V_Operations_Task_Staff when checking if the user can update a closed prep request item
**          02/08/2023 bcg - Update view column name
**          02/13/2023 bcg - Rename parameter to requesterUsername
**
*****************************************************/
(
    @requestName varchar(128),
    @requesterUsername varchar(32),
    @reason varchar(512),
    @materialContainerList varchar(2048),
    @organism varchar(128),
    @biohazardLevel varchar(12),
    @campaign varchar(128),
    @numberofSamples int,
    @sampleNameList varchar(1500),
    @sampleType varchar(128),
    @prepMethod varchar(512),
    @sampleNamingConvention varchar(128),
    @assignedPersonnel varchar(256),
    @requestedPersonnel varchar(256),
    @estimatedPrepTimeDays int,
    @estimatedMSRuns varchar(16),
    @workPackageNumber varchar(64),
    @eusProposalID varchar(10),
    @eusUsageType varchar(50),
    @eusUserID int,                             -- Use Null or 0 if no EUS User ID
    @instrumentGroup varchar(128),              -- Will typically contain an instrument group name; could also contain "None" or any other text
    @datasetType varchar(50),
    @instrumentAnalysisSpecifications varchar(512),
    @comment varchar(2048),
    @priority varchar(12),
    @state varchar(32),                         -- New, On Hold, Prep in Progress, Prep Complete, or Closed
    @stateComment varchar(512),
    @id int output,                             -- Input/output: Sample prep request ID
    @separationGroup varchar(256),              -- Separation group
    @blockAndRandomizeSamples char(3),          -- 'Yes', 'No', or 'na'
    @blockAndRandomizeRuns char(3),             -- 'Yes' or 'No'
    @reasonForHighPriority varchar(1024),
    @tissue varchar(128) = '',
    @mode varchar(12) = 'add',                  -- 'add' or 'update'
    @message varchar(1024) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)

    Declare @currentStateID int

    If IsNull(@state, '') = 'Closed (containers and material)'
    Begin
        -- Prior to September 2018, we would also look for biomaterial (cell cultures)
        -- and would close them if @state was 'Closed (containers and material)'
        -- by calling DoSamplePrepMaterialOperation
        --
        -- We stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
        -- so simply change the state to Closed
        Set @state = 'Closed'
    End

    Declare @requestType varchar(16) = 'Default'
    Declare @logErrors tinyint = 0

    If IsNull(@eusUserID, 0) <= 0
        Set @eusUserID = Null

    Set @estimatedPrepTimeDays = IsNull(@estimatedPrepTimeDays, 1)

    Set @requestedPersonnel = Ltrim(Rtrim(IsNull(@requestedPersonnel, '')))
    Set @assignedPersonnel = Ltrim(Rtrim(IsNull(@assignedPersonnel, 'na')))

    If @assignedPersonnel = ''
        Set @assignedPersonnel = 'na'

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateSamplePrepRequest', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------
    --
    Set @instrumentGroup = IsNull(@instrumentGroup, '')

    Set @datasetType = IsNull(@datasetType, '')

    If Len(IsNull(@estimatedMSRuns, '')) < 1
        RAISERROR ('Estimated number of MS runs was blank; it should be 0 or a positive number', 11, 116)

    If IsNull(@blockAndRandomizeSamples, '') NOT IN ('Yes', 'No', 'NA')
        RAISERROR ('Block And Randomize Samples must be Yes, No, or NA', 11, 116)

    If IsNull(@blockAndRandomizeRuns, '') NOT IN ('Yes', 'No')
        RAISERROR ('Block And Randomize Runs must be Yes or No', 11, 116)

    If Len(IsNull(@reason, '')) < 1
        RAISERROR ('The reason field is required', 11, 116)

    If dbo.udfWhitespaceChars(@requestName, 1) > 0
    Begin
        -- Auto-replace CR, LF, or tabs with spaces
        If CharIndex(Char(10), @requestName) > 0
        Begin
            Set @requestName = Replace(@requestName, Char(10), ' ')
        End

        If CharIndex(Char(13), @requestName) > 0
        Begin
        Set @requestName = Replace(@requestName, Char(13), ' ')
        End

        If CharIndex(Char(9), @requestName) > 0
        Begin
            Set @requestName = Replace(@requestName, Char(9), ' ')
        End
    End

    If @state In ('New', 'Closed')
    Begin
        -- Always clear State Comment when the state is new or closed
        Set @stateComment = ''
    End

    Declare @allowUpdateEstimatedPrepTime tinyint = 0

    If Exists ( SELECT U.U_PRN
                FROM dbo.T_Users U
                     INNER JOIN dbo.T_User_Operations_Permissions UOP
                       ON U.ID = UOP.U_ID
                     INNER JOIN dbo.T_User_Operations UO
                       ON UOP.Op_ID = UO.ID
                WHERE U.U_Status = 'Active' AND
                      UO.Operation = 'DMS_Sample_Preparation' AND
                      U_PRN = @callingUser)
    Begin
          Set @allowUpdateEstimatedPrepTime = 1
    End

    ---------------------------------------------------
    -- Validate priority
    ---------------------------------------------------

    If @priority <> 'Normal' AND ISNULL(@reasonForHighPriority, '') = ''
        RAISERROR ('Priority "%s" requires justification reason to be provided', 11, 37, @priority)

    If Not @priority IN ('Normal', 'High')
        RAISERROR ('Priority should be Normal or High', 11, 37)

    ---------------------------------------------------
    -- Validate instrument group and dataset type
    ---------------------------------------------------
    --
    If NOT (@estimatedMSRuns IN ('0', 'None'))
    Begin
        If @instrumentGroup IN ('none', 'na')
            RAISERROR ('Estimated runs must be 0 or "none" when instrument group is: %s', 11, 1, @instrumentGroup)

        If Try_Parse(@estimatedMSRuns as int) Is Null
            RAISERROR ('Estimated runs must be an integer or "none"', 11, 116)

        If IsNull(@instrumentGroup, '') = ''
            RAISERROR ('Instrument group cannot be empty since the estimated MS run count is non-zero', 11, 117)

        If IsNull(@datasetType, '') = ''
            RAISERROR ('Dataset type cannot be empty since the estimated MS run count is non-zero', 11, 118)

        If IsNull(@separationGroup, '') = ''
            RAISERROR ('Separation group cannot be empty since the estimated MS run count is non-zero', 11, 119)

        ---------------------------------------------------
        -- Determine the Instrument Group
        ---------------------------------------------------

        If NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @instrumentGroup)
        Begin
            -- Try to update instrument group using T_Instrument_Name
            SELECT @instrumentGroup = IN_Group
            FROM T_Instrument_Name
            WHERE IN_Name = @instrumentGroup AND
                  IN_Status <> 'inactive'

        End

        ---------------------------------------------------
        -- Validate instrument group and dataset type
        ---------------------------------------------------

        Declare @datasetTypeID int
        --
        exec @myError = ValidateInstrumentGroupAndDatasetType
                                @datasetType,
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
    execute @campaignID = GetCampaignID @campaign
    --
    If @campaignID = 0
        RAISERROR('Could not find entry in database for campaign "%s"', 11, 14, @campaign)

    ---------------------------------------------------
    -- Resolve material containers
    ---------------------------------------------------

    -- Create temporary table to hold names of material containers as input
    --
    CREATE TABLE #MC (
        [name] varchar(128) not null
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Could not create temporary table for material container list', 11, 50)

    -- Get names of material containers from list argument into table
    --
    INSERT INTO #MC ([name])
    SELECT item FROM MakeTableFromList(@materialContainerList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Could not populate temporary table for material container list', 11, 51)

    -- Verify that material containers exist
    --
    Declare @cnt int = -1

    SELECT @cnt = count(*)
    FROM #MC
    WHERE [name] not in (
        SELECT Tag
        FROM T_Material_Containers
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Was not able to check for material containers in database', 11, 52)
    --
    If @cnt <> 0
        RAISERROR ('One or more material containers was not in database', 11, 53)

    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------

    Declare @organismID int
    execute @organismID = GetOrganismID @organism
    If @organismID = 0
        RAISERROR ('Could not find entry in database for organism "%s"', 11, 38, @organism)

    ---------------------------------------------------
    -- Resolve @tissue to BTO identifier
    ---------------------------------------------------

    Declare @tissueIdentifier varchar(24)
    Declare @tissueName varchar(128)
    Declare @errorCode int

    EXEC @errorCode = GetTissueID
        @tissueNameOrID=@tissue,
        @tissueIdentifier=@tissueIdentifier output,
        @tissueName=@tissueName output

    If @errorCode = 100
        RAISERROR ('Could not find entry in database for tissue "%s"', 11, 41, @tissue)
    Else If @errorCode > 0
        RAISERROR ('Could not resolve tissue name or id: "%s"', 11, 41, @tissue)

    ---------------------------------------------------
    -- Force values of some properties for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin
        Set @state = 'New'
        Set @assignedPersonnel = 'na'
    End

    ---------------------------------------------------
    -- Validate requested and assigned personnel
    -- Names should be in the form "Last Name, First Name (PRN)"
    ---------------------------------------------------

    Declare @result Int

    Exec @result = ValidateRequestUsers
        @requestName, 'AddUpdateSamplePrepRequest',
        @requestedPersonnel = @requestedPersonnel Output,
        @assignedPersonnel = @assignedPersonnel Output,
        @requireValidRequestedPersonnel= 1,
        @message = @message Output

    If @result > 0
    Begin
        If IsNull(@message, '') = ''
        Begin
            Set @message = 'Error validating the requested and assigned personnel'
        End

        RAISERROR (@message, 11, 37)
    End

    ---------------------------------------------------
    -- Convert state name to ID
    ---------------------------------------------------

    Declare @stateID int = 0
    --
    SELECT @stateID = State_ID
    FROM  T_Sample_Prep_Request_State_Name
    WHERE (State_Name = @state)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error trying to resolving state name', 11, 83)
    --
    If @stateID = 0
        RAISERROR ('No entry could be found in database for state "%s"', 11, 23, @state)

    ---------------------------------------------------
    -- Validate EUS type, proposal, and user list
    --
    -- This procedure accepts a list of EUS User IDs,
    -- so we convert to a string before calling it,
    -- then convert back to an integer afterward
    ---------------------------------------------------

    Declare @eusUsageTypeID int
    Declare @eusUsersList varchar(1024) = ''

    Declare @addingItem tinyint = 0
    If @mode = 'add'
    Begin
        Set @addingItem = 1
    End

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
                        @msg Output,
                        @autoPopulateUserListIfBlank = 0,
                        @samplePrepRequest = 1,
                        @experimentID = 0,
                        @campaignID = @campaignID,
                        @addingItem = @addingItem

    If @myError <> 0
        RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
    End

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
    Begin
        Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is deactivated', 0, '; ', 1024)
    End
    Else
    Begin
        If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackageNumber And Charge_Code_State = 0)
        Begin
            Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackageNumber + ' is likely deactivated', 0, '; ', 1024)
        End
    End

    -- Make sure the Work Package is capitalized properly
    --
    SELECT @workPackageNumber = Charge_Code
    FROM T_Charge_Code
    WHERE Charge_Code = @workPackageNumber

    ---------------------------------------------------
    -- Auto-change separation type to separation group, if applicable
    ---------------------------------------------------
    --
    If Not Exists (SELECT * FROM T_Separation_Group WHERE Sep_Group = @separationGroup)
    Begin
        Declare @separationGroupAlt varchar(64) = ''

        SELECT @separationGroupAlt = Sep_Group
        FROM T_Secondary_Sep
        WHERE SS_Name = @separationGroup AND
              SS_Active = 1

        If IsNull(@separationGroupAlt, '') <> ''
            Set @separationGroup = @separationGroupAlt
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        Declare @currentAssignedPersonnel varchar(256)
        Declare @requestTypeExisting varchar(16)
        Set @currentStateID = 0
        --
        SELECT
            @tmp = ID,
            @currentStateID = State,
            @currentAssignedPersonnel = Assigned_Personnel,
            @requestTypeExisting = Request_Type
        FROM  T_Sample_Prep_Request
        WHERE (ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 7)

        -- Changes not allowed if in "closed" state
        --
        If @currentStateID = 5 AND NOT EXISTS (SELECT * FROM V_Operations_Task_Staff WHERE username = @callingUser)
            RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

        -- Don't allow change to "Prep in Progress" unless someone has been assigned
        If @state = 'Prep in Progress' AND ((@assignedPersonnel = '') OR (@assignedPersonnel = 'na'))
            RAISERROR ('State cannot be changed to "Prep in Progress" unless someone has been assigned', 11, 84)

        If @requestTypeExisting <> @requestType
            RAISERROR ('Cannot edit requests of type %s with the sample_prep_request page; use https://dms2.pnl.gov/rna_prep_request/report', 11, 7, @requestTypeExisting)
    End

    If @mode = 'add'
    Begin
        -- Make sure the work package number is not inactive
        --
        Declare @activationState tinyint = 10
        Declare @activationStateName varchar(128)

        SELECT @activationState = CCAS.Activation_State,
               @activationStateName = CCAS.Activation_State_Name
        FROM T_Charge_Code CC
             INNER JOIN T_Charge_Code_Activation_State CCAS
               ON CC.Activation_State = CCAS.Activation_State
        WHERE (CC.Charge_Code = @workPackageNumber)

        If @activationState >= 3
            RAISERROR ('Cannot use inactive Work Package "%s" for a new sample prep request', 11, 8, @workPackageNumber)
    End

    ---------------------------------------------------
    -- Check for name collisions
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        IF EXISTS (SELECT * FROM T_Sample_Prep_Request WHERE Request_Name = @requestName)
            RAISERROR ('Cannot add: Request "%s" already in database', 11, 8, @requestName)

    End
    Else
    Begin
        IF EXISTS (SELECT * FROM T_Sample_Prep_Request WHERE Request_Name = @requestName AND ID <> @id)
            RAISERROR ('Cannot rename: Request "%s" already in database', 11, 8, @requestName)
    End

    Set @logErrors = 1

    Declare @transName varchar(32) = 'AddUpdateSamplePrepRequest'

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        Begin transaction @transName

        INSERT INTO T_Sample_Prep_Request (
            Request_Name,
            Requester_PRN,
            Reason,
            Organism,
            Tissue_ID,
            Biohazard_Level,
            Campaign,
            Number_of_Samples,
            Sample_Name_List,
            Sample_Type,
            Prep_Method,
            Sample_Naming_Convention,
            Requested_Personnel,
            Assigned_Personnel,
            Estimated_Prep_Time_Days,
            Estimated_MS_runs,
            Work_Package_Number,
            EUS_UsageType,
            EUS_Proposal_ID,
            EUS_User_ID,
            Instrument_Analysis_Specifications,
            Comment,
            Priority,
            State,
            State_Comment,
            Instrument_Group,
            Dataset_Type,
            Separation_Type,
            BlockAndRandomizeSamples,
            BlockAndRandomizeRuns,
            Reason_For_High_Priority,
            Request_Type,
            Material_Container_List
        ) VALUES (
            @requestName,
            @requesterUsername,
            @reason,
            @organism,
            @tissueIdentifier,
            @biohazardLevel,
            @campaign,
            @numberofSamples,
            @sampleNameList,
            @sampleType,
            @prepMethod,
            @sampleNamingConvention,
            @requestedPersonnel,
            @assignedPersonnel,
            Case When @allowUpdateEstimatedPrepTime > 0 Then @estimatedPrepTimeDays Else 0 End,
            @estimatedMSRuns,
            @workPackageNumber,
            @eusUsageType,
            @eusProposalID,
            @eusUserID,
            @instrumentAnalysisSpecifications,
            @comment,
            @priority,
            @stateID,
            @stateComment,
            @instrumentGroup,
            @datasetType,
            @separationGroup,
            @blockAndRandomizeSamples,
            @blockAndRandomizeRuns,
            @reasonForHighPriority,
            @requestType,
            @materialContainerList
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed: %d', 11, 7, @myError)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

        commit transaction @transName

        -- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @id, @callingUser,
                                    @entryDateColumnName='Date_of_Change', @enteredByColumnName='System_Account'

    End -- Add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Declare @currentEstimatedPrepTimeDays Int

        SELECT @currentEstimatedPrepTimeDays = Estimated_Prep_Time_Days
        FROM T_Sample_Prep_Request
        WHERE ID = @id

        Begin transaction @transName

        UPDATE T_Sample_Prep_Request
        SET
            Request_Name = @requestName,
            Requester_PRN = @requesterUsername,
            Reason = @reason,
            Material_Container_List = @materialContainerList,
            Organism = @organism,
            Tissue_ID = @tissueIdentifier,
            Biohazard_Level = @biohazardLevel,
            Campaign = @campaign,
            Number_of_Samples = @numberofSamples,
            Sample_Name_List = @sampleNameList,
            Sample_Type = @sampleType,
            Prep_Method = @prepMethod,
            Sample_Naming_Convention = @sampleNamingConvention,
            Requested_Personnel = @requestedPersonnel,
            Assigned_Personnel = @assignedPersonnel,
            Estimated_Prep_Time_Days = Case When @allowUpdateEstimatedPrepTime > 0 Then @estimatedPrepTimeDays Else Estimated_Prep_Time_Days End,
            Estimated_MS_runs = @estimatedMSRuns,
            Work_Package_Number = @workPackageNumber,
            EUS_Proposal_ID = @eusProposalID,
            EUS_UsageType = @eusUsageType,
            EUS_User_ID = @eusUserID,
            Instrument_Analysis_Specifications = @instrumentAnalysisSpecifications,
            Comment = @comment,
            Priority = @priority,
            State = @stateID,
            StateChanged = Case When @currentStateID = @stateID Then StateChanged Else GetDate() End,
            State_Comment = @stateComment,
            Instrument_Group = @instrumentGroup,
            Instrument_Name = Null,
            Dataset_Type = @datasetType,
            Separation_Type = @separationGroup,
            BlockAndRandomizeSamples = @blockAndRandomizeSamples,
            BlockAndRandomizeRuns = @blockAndRandomizeRuns,
            Reason_For_High_Priority = @reasonForHighPriority
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%d"', 11, 4, @id)

        commit transaction @transName

        -- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @id, @callingUser,
                                    @entryDateColumnName='Date_of_Change', @enteredByColumnName='System_Account'

        If @currentEstimatedPrepTimeDays <> @estimatedPrepTimeDays And @allowUpdateEstimatedPrepTime = 0
        Begin
            Set @msg = 'Not updating estimated prep time since user is not a sample prep request staff member'
            Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
        End

    End -- update mode

    End Try
    Begin Catch
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Request ' + @requestName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateSamplePrepRequest'
        End

    End Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSamplePrepRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateSamplePrepRequest] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateSamplePrepRequest] TO [Limited_Table_Write] AS [dbo]
GO
