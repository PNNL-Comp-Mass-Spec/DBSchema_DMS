/****** Object:  StoredProcedure [dbo].[AddRequestedRunFractions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddRequestedRunFractions]
/****************************************************
**
**  Desc:   Adds requested runs based on a parent requested run that has separation group LC-NanoHpH-6, LC-NanoSCX-6, or similar
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/22/2020 mem - Initial Version
**          10/23/2020 mem - Set the Origin of the new requested runs to "Fraction"
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use ReplaceCharacterCodes to replace character codes with punctuation marks
**                         - Use RemoveCrLf to replace linefeeds with semicolons
**          05/25/2021 mem - Append new messages to @message (including from LookupEUSFromExperimentSamplePrep)
**                         - Expand @message to varchar(1024)
**          05/27/2021 mem - Specify @samplePrepRequest, @experimentID, @campaignID, and @addingItem when calling ValidateEUSUsage
**          06/01/2021 mem - Add newly created requested run fractions to the parent request's batch (which will be 0 if not in a batch)
**                         - Raise an error if @mode is invalid
**          10/13/2021 mem - Append EUS User ID list to warning message
**                         - Do not call PostLogEntry where @mode is 'preview'
**          10/22/2021 mem - Use a new instrument group for the new requested runs
**          11/15/2021 mem - If the the instrument group for the source request is the target instrument group instead of a fraction based group, auto update the source instrument group
**          01/15/2022 mem - Copy date created from the parent requested run to new requested runs, allowing Days in Queue on the list report to be based on the parent requested run's creation date
**
*****************************************************/
(
    @sourceRequestID int,
    @separationGroup varchar(64) = 'LC-Formic_2hr',
    @requestorPRN varchar(80),                      -- Supports either simply a username, or 'LastName, FirstName (Username)'
    @instrumentSettings varchar(512) = 'na',
    @stagingLocation varchar(64) = null,
    @wellplateName varchar(64) = '',                -- If (lookup), will look for a wellplate defined in T_Experiments
    @wellNumber varchar(24) = '',                   -- If (lookup), will look for a well number defined in T_Experiments
    @vialingConc varchar(32) = null,
    @vialingVol varchar(32) = null,
    @comment varchar(1024) = 'na',
    @workPackage varchar(50),                       -- Work package; could also contain "(lookup)".  May contain 'none' for automatically created requested runs (and those will have @autoPopulateUserListIfBlank=1)
    @eusUsageType varchar(50),
    @eusProposalID varchar(10) = 'na',
    @eusUserID varchar(512) = '',                   -- EUS User ID (integer); also supports the form "Baker, Erin (41136)"
    @mrmAttachment varchar(128),
    @mode varchar(12) = 'add',                      -- 'add' or 'preview'
    @message varchar(1024) output,
    @autoPopulateUserListIfBlank tinyint = 0,       -- When 1, will auto-populate @eusUserID if it is empty and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
    @callingUser varchar(128) = '',
    @logDebugMessages tinyint = 0
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)
    Declare @instrumentMatch varchar(64)

    -- Default priority at which new requests will be created
    Declare @defaultPriority int = 0

    Declare @debugMsg varchar(512)
    Declare @logErrors tinyint = 0
    Declare @raiseErrorOnMultipleEUSUsers tinyint = 1

    Declare @sourceRequestName varchar(128) = ''
    Declare @sourceRequestBatchID int = 0
    
    Declare @instrumentGroup varchar(64)
    Declare @targetInstrumentGroup varchar(64)
    Declare @fractionBasedInstrumentGroup varchar(64) = ''

    Declare @msType varchar(20)
    Declare @experimentID int
    Declare @sourceSeparationGroup varchar(64)
    Declare @sourceStatus varchar(24)
    Declare @sourceCreated datetime

    Declare @status varchar(24) = 'Active'
    Declare @experimentName varchar(128)

    Declare @fractionCount int = 0
    Declare @targetGroupFractionCount int = 0

    Declare @mrmAttachmentID int

    Declare @fractionNumber int
    Declare @requestName varchar(128)
    Declare @requestID int
    Declare @requestIdList varchar(1024) = ''

    Declare @firstRequest varchar(128)
    Declare @lastRequest varchar(128)

    Declare @continue tinyint = 0
    
    Set @logDebugMessages = IsNull(@logDebugMessages, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddRequestedRunFractions', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Validate input fields'
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    If IsNull(@sourceRequestID, 0) = 0
        RAISERROR ('Source request ID not provided', 11, 110)
    --
    If IsNull(@requestorPRN, '') = ''
        RAISERROR ('Requestor payroll number/HID was blank', 11, 113)
    --
    If IsNull(@separationGroup, '') = ''
        RAISERROR ('Separation group was blank', 11, 114)
    --
    If IsNull(@workPackage, '') = ''
        RAISERROR ('Work package was blank', 11, 116)

    Set @mode = ISNULL(@mode, '')

    If Not @mode in ('add', 'preview')
    Begin
        RAISERROR ('Invalid mode: should be "add" or "preview", not "%s"', 11, 117, @mode)
    End

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.ReplaceCharacterCodes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.RemoveCrLf(@comment)

    If IsNull(@wellplateName, '') IN ('', 'na')
        Set @wellplateName = null

    If IsNull(@wellNumber, '') IN ('', 'na')
        Set @wellNumber = null

    Set @mrmAttachment = ISNULL(@mrmAttachment, '')

    ---------------------------------------------------
    -- Create a temporary table to track the IDs of new requested runs
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_NewRequests (
        Fraction_Number int NOT NULL,
        Request_Name varchar(128) NOT NULL,
        Request_ID int NULL
    )

    ---------------------------------------------------
    -- Lookup information from the source requested run
    ---------------------------------------------------

    SELECT @sourceRequestName = RR.RDS_Name,
           @instrumentGroup = RR.RDS_instrument_group,
           @msType = T_DatasetTypeName.DST_name,
           @experimentID = RR.Exp_ID,
           @sourceSeparationGroup = RR.RDS_Sec_Sep,
           @sourceStatus = RR.RDS_Status,
           @sourceRequestBatchID = IsNull(RR.RDS_BatchID, 0),
           @sourceCreated = RR.RDS_created
    FROM T_Requested_Run RR INNER JOIN T_DatasetTypeName
           ON RR.RDS_type_ID = T_DatasetTypeName.DST_Type_ID
    WHERE RR.ID = @sourceRequestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    IF @myRowCount = 0
    Begin
        RAISERROR ('Source request ID not found: %d', 11, 117, @sourceRequestID)
    End

    Declare @badCh varchar(128) = dbo.ValidateChars(@sourceRequestName, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            RAISERROR ('Source requested run name may not contain spaces', 11, 118)
        Else
            RAISERROR ('Source requested run name may not contain the character(s) "%s"', 11, 118, @badCh)
    End

    If @sourceStatus <> 'Active'
    Begin
        Set @requestName = @sourceRequestName + '_f01%'

        If EXISTS (SELECT * from T_Requested_Run WHERE RDS_Name Like @requestName)
            RAISERROR ('Fraction-based requested runs have already been created for this requested run; nothing to do', 11, 119)
        Else
            RAISERROR ('Source requested run is not active; cannot continue', 11, 119)
    End

    Set @sourceRequestName = Ltrim(Rtrim(@sourceRequestName))

    Declare @nameLength int = Len(@sourceRequestName)

    If @nameLength > 64
    Begin
        RAISERROR ('Requested run name is too long (%d characters); max length is 64 characters', 11, 119, @nameLength)
    End

    If ISNULL(@instrumentGroup, '') = ''
    Begin
        RAISERROR ('Source request does not have an instrument group defined', 11, 120)
    End

    If ISNULL(@msType, '') = ''
    Begin
        RAISERROR ('Source request does not have an dataset type defined', 11, 120)
    End

    ---------------------------------------------------
    -- Lookup StatusID
    ---------------------------------------------------
    --
    Declare @statusID int = 0

    SELECT @statusID = State_ID
    FROM T_Requested_Run_State_Name
    WHERE State_Name = @status

    ---------------------------------------------------
    -- Validate that the experiment exists
    -- Lookup wellplate and well number if either is (lookup)
    ---------------------------------------------------
    --
    SELECT @experimentName = Experiment_Num,
           @wellplateName = CASE WHEN @wellplateName = '(lookup)' THEN EX_wellplate_num
                                 ELSE @wellplateName
                            END,
           @wellNumber = CASE WHEN @wellNumber = '(lookup)' THEN EX_well_num
                              ELSE @wellNumber
                         END
    FROM T_Experiments
    WHERE Exp_ID = @experimentID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error looking up experiment', 11, 17)
    --
    If @myRowCount = 0
        RAISERROR ('Could not find entry in database for experiment ID %d', 11, 18, @experimentID)

    ---------------------------------------------------
    -- Verify user ID for operator PRN
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call GetUserID for ' + @requestorPRN
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    Declare @userID int
    execute @userID = GetUserID @requestorPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @requestorPRN contains simply the username
        --
        SELECT @requestorPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @requestorPRN
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newPRN varchar(64)

        exec AutoResolveNameToPRN @requestorPRN, @matchCount output, @newPRN output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @requestorPRN
            Set @requestorPRN = @newPRN
        End
        Else
        Begin
            RAISERROR ('Could not find entry in database for requestor PRN "%s"', 11, 19, @requestorPRN)
            return 51019
        End
    End

    ---------------------------------------------------
    -- Determine the instrument group to use for the new requested runs
    ---------------------------------------------------

    SELECT @targetInstrumentGroup = Target_Instrument_Group
    FROM T_Instrument_Group
    WHERE IN_Group = @instrumentGroup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        RAISERROR ('Could not find entry in database for instrument group "%s"', 11, 19, @instrumentGroup)
        return 51020
    End
    
    If IsNull(@targetInstrumentGroup, '') = ''
    Begin
        -- If the user specified the target group instead of the instrument group that ends with _Frac, auto change things
        SELECT @fractionBasedInstrumentGroup = IN_Group
        FROM T_Instrument_Group
        WHERE Target_Instrument_Group = @instrumentGroup
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 1
        Begin
            Set @instrumentGroup = @fractionBasedInstrumentGroup

            SELECT @targetInstrumentGroup = Target_Instrument_Group
            FROM T_Instrument_Group
            WHERE IN_Group = @instrumentGroup
        End
    End

    If IsNull(@targetInstrumentGroup, '') = ''
    Begin
        RAISERROR ('Instrument group "%s" does not have a valid target instrument group defined; contact a DMS admin', 11, 19, @instrumentGroup)
        return 51021
    End

    ---------------------------------------------------
    -- Validate instrument group and dataset type
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'ValidateInstrumentGroupAndDatasetType for ' + @msType
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    Declare @datasetTypeID int
    --
    exec @myError = ValidateInstrumentGroupAndDatasetType
                            @msType,
                            @targetInstrumentGroup output,
                            @datasetTypeID output,
                            @msg output
    If @myError <> 0
        RAISERROR ('ValidateInstrumentGroupAndDatasetType: %s', 11, 1, @msg)

    ---------------------------------------------------
    -- Examine the fraction count of the source separation group
    ---------------------------------------------------
    --
    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Examine fraction counts of source and target separation groups: ' + @sourceSeparationGroup + ' and ' + @separationGroup
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    SELECT @fractionCount = Fraction_Count
    FROM T_Separation_Group
    WHERE Sep_Group = @sourceSeparationGroup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    IF @myRowCount = 0
    Begin
        RAISERROR ('Separation group of the source request not found: %s', 11, 99, @sourceSeparationGroup)
    End

    If @fractionCount = 0
    Begin
        RAISERROR ('Source request separation group should be fraction-based (LC-NanoHpH, LC-NanoSCX, etc.); %s is invalid', 11, 99, @sourceSeparationGroup)
    End

    ---------------------------------------------------
    -- Examine the fraction count of the separation group for the new requested runs
    -- The target group should not be fraction based
    ---------------------------------------------------
    --
    SELECT @targetGroupFractionCount = Fraction_Count
    FROM T_Separation_Group
    WHERE Sep_Group = @separationGroup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    IF @myRowCount = 0
    Begin
        RAISERROR ('Separation group not found: %s', 11, 99, @separationGroup)
    End

    If @targetGroupFractionCount > 0
    Begin
        RAISERROR ('Separation group for the new requested runs (%s) has a non-zero fraction count value (%d); this is not allowed', 11, 99, @separationGroup, @targetGroupFractionCount)
    End

    ---------------------------------------------------
    -- Resolve ID for MRM attachment
    ---------------------------------------------------
    --
    If @mrmAttachment <> ''
    Begin
        SELECT @mrmAttachmentID = ID
        FROM T_Attachments
        WHERE Attachment_Name = @mrmAttachment
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to look up attachement ID', 11, 73)
    End

    ---------------------------------------------------
    -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
    -- This will update the data in @eusUsageType, @eusProposalID, or @eusUserID if it is "(lookup)"
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Lookup EUS info for: ' + @experimentName
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End
    --
    exec @myError = LookupEUSFromExperimentSamplePrep
                        @myRowCount,
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUserID output,
                        @msg output

    If @myError <> 0
        RAISERROR ('LookupEUSFromExperimentSamplePrep: %s', 11, 1, @msg)

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
    End

    ---------------------------------------------------
    -- Validate EUS type, proposal, and user list
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call ValidateEUSUsage with ' +
            'type ' + IsNull(@eusUsageType, '?Null?') + ', ' +
            'proposal ' + IsNull(@eusProposalID, '?Null?') + ', and ' +
            'user list ' + IsNull(@eusUserID, '?Null?')

        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    -- Note that if @eusUserID contains a list of names in the form "Baker, Erin (41136)",
    -- ValidateEUSUsage will change this into a list of EUS user IDs (integers)

    If Len(@eusUserID) = 0 And @autoPopulateUserListIfBlank > 0
    Begin
        Set @raiseErrorOnMultipleEUSUsers = 0
    End

    Declare @eusUsageTypeID Int

    Declare @addingItem tinyint = 0
    If @mode = 'add'
    Begin
        Set @addingItem = 1
    End

    exec @myError = ValidateEUSUsage
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUserID output,
                        @eusUsageTypeID output,
                        @msg output,
                        @autoPopulateUserListIfBlank,
                        @samplePrepRequest = 0,
                        @experimentID = @experimentID,
                        @campaignID = 0, 
                        @addingItem = @addingItem

    If @myError <> 0
        RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
    End

    Declare @commaPosition Int = CharIndex(',', @eusUserID)
    If @commaPosition > 1
    Begin
        Set @msg = 'Requested runs can only have a single EUS user associated with them; current list: ' + @eusUserID
        Set @message = dbo.AppendToText(@msg, @message, 0, '; ', 1024)

        If @raiseErrorOnMultipleEUSUsers > 0
            RAISERROR ('ValidateEUSUsage: %s', 11, 1, @message)

        -- Only keep the first user
        Set @eusUserID = Left(@eusUserID, @commaPosition - 1)
    End

    ---------------------------------------------------
    -- Lookup misc fields (only applies to experiments with sample prep requests)
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Lookup misc fields for the experiment'
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    exec @myError = LookupOtherFromExperimentSamplePrep
                        @experimentName,
                        @workPackage output,
                        @msg output

    If @myError <> 0
        RAISERROR ('LookupOtherFromExperimentSamplePrep: %s', 11, 1, @msg)

    ---------------------------------------------------
    -- Resolve staging location name to location ID
    ---------------------------------------------------

    Declare @locationID int = null

    If IsNull(@stagingLocation, '') <> ''
    Begin
        SELECT @locationID = ID
        FROM T_Material_Locations
        WHERE Tag = @stagingLocation
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to look up staging location ID', 11, 98)
        --
        If IsNull(@locationID, 0) = 0
            RAISERROR ('Staging location not recognized', 11, 99)

    End

    ---------------------------------------------------
    -- Validate the work package
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Validate the WP'
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    Declare @allowNoneWP tinyint = @autoPopulateUserListIfBlank
    Declare @requireWP tinyint = 1

    SELECT @requireWP = Value
    FROM T_MiscOptions
    WHERE Name = 'RequestedRunRequireWorkpackage'

    If @requireWP = 0
    Begin
        Set @allowNoneWP = 1
    End

    exec @myError = ValidateWP
                        @workPackage,
                        @allowNoneWP,
                        @msg output

    If @myError <> 0
        RAISERROR ('ValidateWP: %s', 11, 1, @msg)

    -- Make sure the Work Package is capitalized properly
    --
    SELECT @workPackage = Charge_Code
    FROM T_Charge_Code
    WHERE Charge_Code = @workPackage

    If @autoPopulateUserListIfBlank = 0
    Begin
        If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Deactivated = 'Y')
        Begin
            Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackage + ' is deactivated', 0, '; ', 1024)
        End
        Else
        Begin
            If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Charge_Code_State = 0)
            Begin
                Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackage + ' is likely deactivated', 0, '; ', 1024)
            End
        End
    End

    If @mode <> 'preview'
    Begin
        -- Validation checks are complete; now enable @logErrors
        Set @logErrors = 1
    End

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Start a new transaction'
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Check for name conflicts'
        exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
    End
    ---------------------------------------------------
    -- Make sure none of the new requested runs will conflict with an existing requested run
    ---------------------------------------------------
    --
    Set @fractionNumber = 1
    While @fractionNumber <= @fractionCount
    Begin
        If @fractionNumber < 10
        Begin
            Set @requestName = @sourceRequestName + '_f0' + CAST(@fractionNumber as varchar(12))
        End
        Else
        Begin
            Set @requestName = @sourceRequestName + '_f' +  CAST(@fractionNumber as varchar(12))
        End

        SELECT @requestID = ID
        FROM T_Requested_Run
        WHERE RDS_Name = @requestName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            RAISERROR ('Name conflict: a requested run named %s already exists, ID %d', 11, 99, @requestName, @requestID)
        End

        INSERT INTO #Tmp_NewRequests (Fraction_Number, Request_Name)
        VALUES (@fractionNumber, @requestName)

        Set @fractionNumber = @fractionNumber + 1
    End

    ---------------------------------------------------
    -- Action for preview mode
    ---------------------------------------------------
    --
    If @mode = 'preview'
    Begin
        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Create preview message'
            exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
        End

        SELECT TOP 1 @firstRequest = Request_Name
        FROM #Tmp_NewRequests
        ORDER BY Fraction_Number

        SELECT TOP 1 @lastRequest = Request_Name
        FROM #Tmp_NewRequests
        ORDER BY Fraction_Number DESC

        Set @msg = 'Would create ' + CAST(@fractionCount as varchar(12)) + ' requested runs named ' + @firstRequest + ' ... ' + @lastRequest + 
                   ' with instrument group ' + @targetInstrumentGroup + ' and separation group ' + @separationGroup
        Set @message = dbo.AppendToText(@msg, @message, 0, '; ', 1024)
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin -- <add>

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Start a new transaction'
            exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
        End

        -- Start transaction
        --
        Begin transaction

        If Len(IsNull(@fractionBasedInstrumentGroup, '')) > 0
        Begin
            -- Fix the instrument group name in the source requested run
            UPDATE T_Requested_Run
            SET RDS_instrument_group = @fractionBasedInstrumentGroup
            WHERE ID = @sourceRequestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        Set @fractionNumber = 1

        While @fractionNumber <= @fractionCount
        Begin
            SELECT @requestName = Request_Name
            FROM #Tmp_NewRequests
            WHERE Fraction_Number = @fractionNumber

            INSERT INTO T_Requested_Run
            (
                RDS_name,
                RDS_Requestor_PRN,
                RDS_comment,
                RDS_created,
                RDS_instrument_group,
                RDS_type_ID,
                RDS_instrument_setting,
                RDS_priority,
                Exp_ID,
                RDS_WorkPackage,
                RDS_BatchID,
                RDS_Well_Plate_Num,
                RDS_Well_Num,
                RDS_internal_standard,
                RDS_EUS_Proposal_ID,
                RDS_EUS_UsageType,
                RDS_Sec_Sep,
                RDS_MRM_Attachment,
                RDS_Origin,
                RDS_Status,
                Vialing_Conc,
                Vialing_Vol,
                Location_Id
            ) VALUES (
                @requestName,
                @requestorPRN,
                @comment,
                @sourceCreated,
                @targetInstrumentGroup,
                @datasetTypeID,
                @instrumentSettings,
                @defaultPriority,
                @experimentID,
                @workPackage,
                @sourceRequestBatchID,
                @wellplateName,
                @wellNumber,
                'none',
                @eusProposalID,
                @eusUsageTypeID,
                @separationGroup,
                @mrmAttachmentID,
                'fraction',
                @status,
                @vialingConc,
                @vialingVol,
                @locationId
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Insert operation failed: "%s"', 11, 7, @requestName)

            Set @requestID = SCOPE_IDENTITY()

            UPDATE #Tmp_NewRequests
            SET Request_ID = @requestID
            WHERE Request_Name = @requestName

            -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
            If Len(@callingUser) > 0
            Begin
                Exec AlterEventLogEntryUser 11, @requestID, @statusID, @callingUser
            End

            If @logDebugMessages > 0
            Begin
                Set @debugMsg = 'Call AssignEUSUsersToRequestedRun'
                exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
            End

            -- Assign users to the request
            --
            exec @myError = AssignEUSUsersToRequestedRun
                                    @requestID,
                                    @eusProposalID,
                                    @eusUserID,
                                    @msg output
            --
            If @myError <> 0
                RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 19, @msg)

            -- Append the new request ID to @requestIdList
            --
            If @requestIdList = ''
                Set @requestIdList = Cast(@requestID as varchar(12))
            Else
                Set @requestIdList = @requestIdList + ', ' + Cast(@requestID as varchar(12))

            -- Increment the fraction
            --
            Set @fractionNumber = @fractionNumber + 1

        End -- </while>

        UPDATE T_Requested_Run
        SET RDS_Status = 'Completed'
        WHERE ID = @sourceRequestID

        If @@trancount > 0
        Begin
            Commit Transaction
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            exec PostLogEntry 'Error', @debugMsg, 'AddRequestedRunFractions'
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Transaction committed'
            exec PostLogEntry 'Debug', @debugMsg, 'AddRequestedRunFractions'
        End

        ---------------------------------------------------
        -- Add new rows to T_Active_Requested_Run_Cached_EUS_Users
        -- We are doing this outside of the above transaction
        ---------------------------------------------------

        Set @continue = 1
        Set @requestID = 0

        While @continue = 1
        Begin
            SELECT TOP 1 @requestID = Request_ID
            FROM #Tmp_NewRequests
            WHERE Request_ID > @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                exec UpdateCachedRequestedRunEUSUsers @requestID
            End
        End

        Set @msg = 'Created new requested runs based on source request ' + CAST(@sourceRequestID as varchar(12)) + ', creating: ' + @requestIdList
        Set @message = dbo.AppendToText(@msg, @message, 0, '; ', 1024)

        EXEC PostLogEntry 'Normal', @message, 'AddRequestedRunFractions'

    End -- </add>

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1500) = @message + '; Source Request ID ' + CAST(@sourceRequestID as varchar(12))
            exec PostLogEntry 'Error', @logMessage, 'AddRequestedRunFractions'
        End

    END CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRunFractions] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRunFractions] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRequestedRunFractions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRequestedRunFractions] TO [Limited_Table_Write] AS [dbo]
GO
