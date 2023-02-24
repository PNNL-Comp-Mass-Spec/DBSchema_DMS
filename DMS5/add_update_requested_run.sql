/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateRequestedRun]
/****************************************************
**
**  Desc:
**      Adds a new entry to the requested dataset table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/11/2002
**          02/15/2003
**          12/05/2003 grk - added wellplate stuff
**          01/05/2004 grk - added internal standard stuff
**          03/01/2004 grk - added manual identity calculation (removed identity column)
**          03/10/2004 grk - repaired manual identity calculation to include history table
**          07/15/2004 grk - added verification of experiment location aux info
**          11/26/2004 grk - changed type of @comment from text to varchar
**          01/12/2004 grk - fixed null return on check existing when table is empty
**          10/12/2005 grk - Added stuff for new work package and proposal fields.
**          02/21/2006 grk - Added stuff for EUS proposal and user tracking.
**          11/09/2006 grk - Fixed error message handling (Ticket #318)
**          01/12/2007 grk - added verification mode
**          01/31/2007 grk - added verification for @requestorPRN (Ticket #371)
**          03/19/2007 grk - added @defaultPriority (Ticket #421) (set it back to 0 on 04/25/2007)
**          04/25/2007 grk - get new ID from UDF (Ticket #446)
**          04/30/2007 grk - added better name validation (Ticket #450)
**          07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**          07/11/2007 grk - modified to look up EUS fields from sample prep request (Ticket #499)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          07/30/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - factored out instrument name and dataset type validation to ValidateInstrumentAndDatasetType (Ticket #512)
**          09/06/2007 grk - added call to LookupInstrumentRunInfoFromExperimentSamplePrep (Ticket #512)
**          09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**          04/09/2008 grk - Added secondary separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          06/03/2009 grk - look up work package (Ticket #739)
**          07/27/2009 grk - added lookup for wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          02/28/2010 grk - added add-auto mode
**          03/02/2010 grk - added status field to requested run
**          03/10/2010 grk - fixed issue with status validation
**          03/27/2010 grk - fixed problem creating new requests with "Completed" status.
**          04/20/2010 grk - fixed problem with experiment lookup validation
**          04/21/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @requestorPRN contains a person's real name rather than their username
**          08/27/2010 mem - Now auto-switching @instrumentName to be instrument group instead of instrument name
**          09/01/2010 mem - Added parameter @SkipTransactionRollback
**          09/09/2010 mem - Added parameter @autoPopulateUserListIfBlank
**          07/29/2011 mem - Now querying T_Requested_Run with both @reqName and @status when the mode is update or check_update
**          11/29/2011 mem - Tweaked warning messages when checking for existing request
**          12/05/2011 mem - Updated @transName to use a custom transaction name
**          12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**                         - Added parameter @callingUser, which is passed to AlterEventLogEntryUser
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**          01/09/2012 grk - Added @secSep to LookupInstrumentRunInfoFromExperimentSamplePrep
**          10/19/2012 mem - Now auto-updating secondary separation to separation group name when creating a new requested run
**          05/08/2013 mem - Added @VialingConc and @VialingVol
**          06/05/2013 mem - Now validating @WorkPackageNumber against T_Charge_Code
**          06/06/2013 mem - Now showing warning if the work package is deactivated
**          11/12/2013 mem - Added @requestIDForUpdate
**                         - Now auto-capitalizing @instrumentGroup
**          08/19/2014 mem - Now copying @instrumentName to @instrumentGroup during the initial validation
**          09/17/2014 mem - Now auto-updating @status to 'Active' if adding a request yet @status is null
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/29/2016 mem - Now looking up setting for 'RequestedRunRequireWorkpackage' using T_MiscOptions
**          07/20/2016 mem - Tweak error message
**          11/16/2016 mem - Call UpdateCachedRequestedRunEUSUsers to update T_Active_Requested_Run_Cached_EUS_Users
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Add parameter @logDebugMessages
**          02/07/2017 mem - Change default for @logDebugMessages to 0
**          06/13/2017 mem - Rename @operPRN to @requestorPRN
**                         - Make sure the Work Package is capitalized properly
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/12/2017 mem - Add @stagingLocation (points to T_Material_Locations)
**          06/12/2018 mem - Send @maxLength to AppendToText
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          09/03/2018 mem - Apply a maximum length restriction of 64 characters to @reqName when creating a new requested run
**          12/10/2018 mem - Report an error if the comment contains 'experiment_group/show/0000'
**          07/01/2019 mem - Allow @workPackage to be none if the Request is not active and either the Usage Type is Maintenance or the name starts with "AutoReq_"
**          02/03/2020 mem - Raise an error if @eusUsersList contains multiple user IDs (since ERS only allows for a single user to be associated with a dataset)
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use ReplaceCharacterCodes to replace character codes with punctuation marks
**                         - Use RemoveCrLf to replace linefeeds with semicolons
**          05/25/2021 mem - Append new messages to @message (including from LookupEUSFromExperimentSamplePrep)
**                         - Expand @message to varchar(1024)
**          05/26/2021 mem - Check for undefined EUS Usage Type (ID = 1)
**                     bcg - Bug fix: use @eusUsageTypeID to prevent use of EUS Usage Type "Undefined"
**                     mem - When @mode is 'add', 'add-auto', or 'check_add', possibly override the EUSUsageType based on the campaign's EUS Usage Type
**          05/27/2021 mem - Refactor EUS Usage validation code into ValidateEUSUsage
**          05/31/2021 mem - Add output parameter @resolvedInstrumentInfo
**          06/01/2021 mem - Update the message stored in @resolvedInstrumentInfo
**          10/06/2021 mem - Add @batch, @block, and @runOrder
**          02/17/2022 mem - Update requestor username warning
**          05/23/2022 mem - Rename requester username argument and update username warning
**          11/25/2022 mem - Rename parameter to @wellplate
**          02/10/2023 mem - Call UpdateCachedRequestedRunBatchStats
**
*****************************************************/
(
    @reqName varchar(128),
    @experimentNum varchar(64),
    @requesterPRN varchar(64),
    @instrumentName varchar(64),                -- Instrument group; could also contain "(lookup)"
    @workPackage varchar(50),                   -- Work package; could also contain "(lookup)".  May contain 'none' for automatically created requested runs (and those will have @autoPopulateUserListIfBlank=1)
    @msType varchar(20),
    @instrumentSettings varchar(512) = 'na',
    @wellplate varchar(64) = 'na',              -- Wellplate name
    @wellNum varchar(24) = 'na',
    @internalStandard varchar(50) = 'na',
    @comment varchar(1024) = 'na',
    @batch int = 0,                             -- When updating an existing requested run, if this is null or 0, the requested run will be removed from the batch
    @block int = 0,                             -- When updating an existing requested run, if this is null, Block will be set to 0
    @runOrder int = 0,                          -- When updating an existing requested run, if this is null, Run_Order will be set to 0
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50),
    @eusUsersList varchar(1024) = '',           -- EUS User ID (integer); also supports the form "Baker, Erin (41136)". Prior to February 2020, supported a comma separated list of EUS user IDs
    @mode varchar(12) = 'add',                  -- 'add', 'check_add', 'update', 'check_update', or 'add-auto'
    @request int output,
    @message varchar(1024) output,
    @secSep varchar(64) = 'LC-Formic_100min',   -- Separation group
    @mrmAttachment varchar(128),
    @status VARCHAR(24) = 'Active',             -- 'Active', 'Inactive', 'Completed'
    @skipTransactionRollback tinyint = 0,       -- This is set to 1 when stored procedure AddUpdateDataset calls this stored procedure
    @autoPopulateUserListIfBlank tinyint = 0,   -- When 1, will auto-populate @eusUsersList if it is empty and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
    @callingUser varchar(128) = '',
    @vialingConc varchar(32) = null,
    @vialingVol varchar(32) = null,
    @stagingLocation varchar(64) = null,
    @requestIDForUpdate int = null,             -- Only used if @mode is 'update' or 'check_update' and only used if not 0 or null.  Can be used to rename an existing request
    @logDebugMessages tinyint = 0,
    @resolvedInstrumentInfo varchar(256) = '' output      -- Output parameter that lists the the instrument group, run type, and separation group; used by AddRequestedRuns when previewing updates
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @resolvedInstrumentInfo = ''

    Declare @msg varchar(512)
    Declare @instrumentMatch varchar(64)
    Declare @separationGroup varchar(64) = @secSep

    -- default priority at which new requests will be created
    Declare @defaultPriority int = 0

    Declare @currentBatch int = 0

    Declare @debugMsg varchar(512)
    Declare @logErrors tinyint = 0
    Declare @raiseErrorOnMultipleEUSUsers tinyint = 1

    Set @logDebugMessages = IsNull(@logDebugMessages, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateRequestedRun', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Preliminary steps
    ---------------------------------------------------
    --
    Declare @requestOrigin CHAR(4) = 'user'
    --
    If @mode = 'add-auto'
    Begin
        Set @mode = 'add'
        Set @requestOrigin = 'auto'
    END

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Validate input fields'
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    If IsNull(@reqName, '') = ''
        RAISERROR ('Request name was blank', 11, 110)
    --
    If IsNull(@experimentNum, '') = ''
        RAISERROR ('Experiment number was blank', 11, 111)
    --
    If IsNull(@requesterPRN, '') = ''
        RAISERROR ('Requester username was blank', 11, 113)
    --
    Declare @instrumentGroup varchar(64) = @instrumentName
    If IsNull(@instrumentGroup, '') = ''
        RAISERROR ('Instrument group was blank', 11, 114)
    --
    If IsNull(@msType, '') = ''
        RAISERROR ('Dataset type was blank', 11, 115)
    --
    If IsNull(@workPackage, '') = ''
        RAISERROR ('Work package was blank', 11, 116)

    Set @requestIDForUpdate = IsNull(@requestIDForUpdate, 0)

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.ReplaceCharacterCodes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.RemoveCrLf(@comment)

    If @comment like '%experiment_group/show/0000%'
        RAISERROR ('Please reference a valid experiment group ID, not 0000', 11, 116)

    If @comment like '%experiment_group/show/0%'
        RAISERROR ('Please reference a valid experiment group ID', 11, 116)

    Set @batch = IsNull(@batch, 0)
    Set @block = IsNull(@block, 0)
    Set @runOrder = IsNull(@runOrder, 0)

    ---------------------------------------------------
    -- Validate name
    ---------------------------------------------------

    Declare @badCh varchar(128) = dbo.ValidateChars(@reqName, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            RAISERROR ('Requested run name may not contain spaces', 11, 1)
        Else
            RAISERROR ('Requested run name may not contain the character(s) "%s"', 11, 1, @badCh)
    End

    Set @reqName = Ltrim(Rtrim(@reqName))

    Declare @nameLength int = Len(@reqName)

    If @nameLength > 64 And @mode IN ('add', 'check_add') And @requestOrigin <> 'auto'
    Begin
        RAISERROR ('Requested run name is too long (%d characters); max length is 64 characters', 11, 2, @nameLength)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    -- Note that if a request is recycled, the old and new requests
    --  will have the same name but different IDs
    -- When @mode is Update, we should first look for an existing request
    --  with name @reqName and status @status
    -- If a match is not found, then simply look for a request with the same name
    ---------------------------------------------------

    Declare @requestID int = 0
    Declare @oldReqName varchar(128) = ''
    Declare @oldEusProposalID varchar(10) = ''
    Declare @oldStatus varchar(24) = ''
    Declare @matchFound tinyint = 0

    If @mode IN ('update', 'check_update')
    Begin
        If @requestIDForUpdate > 0
        Begin
            SELECT @oldReqName = RDS_Name,
                   @requestID = ID,
                   @oldEusProposalID = RDS_EUS_Proposal_ID,
                   @oldStatus = RDS_Status
            FROM T_Requested_Run
            WHERE ID = @requestIDForUpdate
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error looking for request ID %d', 11, 7, @requestIDForUpdate)

            If @oldReqName <> @reqName
            Begin
                If @status <> 'Active'
                    RAISERROR ('Requested run is not active; cannot rename: "%s"', 11, 7, @oldReqName)

                If Exists (Select * from T_Requested_Run Where RDS_Name = @reqName)
                    RAISERROR ('Cannot rename "%s" since new name already exists: "%s"', 11, 7, @oldReqName, @reqName)
            End

            If @myRowCount > 0
                Set @matchFound = 1

        End
        Else
        Begin
            SELECT @oldReqName = RDS_Name,
                   @requestID = ID,
                   @oldEusProposalID = RDS_EUS_Proposal_ID,
                   @oldStatus = RDS_Status
            FROM T_Requested_Run
            WHERE RDS_Name = @reqName AND
                  RDS_Status = @status
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error trying to find existing request: "%s"', 11, 7, @reqName)

            If @myRowCount > 0
                Set @matchFound = 1
        End
    End

    If @matchFound = 0
    Begin
        -- Match not found when filtering on Status
        -- Query again, but this time ignore RDS_Status
        --
        SELECT @oldReqName = RDS_Name,
               @requestID = ID,
               @oldEusProposalID = RDS_EUS_Proposal_ID,
               @oldStatus = RDS_Status
        FROM T_Requested_Run
        WHERE RDS_Name = @reqName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to find existing request: "%s"', 11, 7, @reqName)
    End

    -- Need non-null request even if we are just checking
    --
    Set @request = @requestID

    -- Cannot create an entry that already exists
    --
    If @requestID <> 0 and (@mode IN ('add', 'check_add'))
        RAISERROR ('Cannot add: Requested Run "%s" already in the database; cannot add', 11, 4, @reqName)

    -- Cannot update a non-existent entry
    --
    If @requestID = 0 and (@mode IN ('update', 'check_update'))
    Begin
        If @requestIDForUpdate > 0
            RAISERROR ('Cannot update: Requested Run ID "%d" is not in the database; cannot update', 11, 4, @requestIDForUpdate)
        Else
            RAISERROR ('Cannot update: Requested Run "%s" is not in the database; cannot update', 11, 4, @reqName)
    End


    ---------------------------------------------------
    -- Confirm that the new status value is valid
    ---------------------------------------------------
    --
    Set @status = IsNull(@status, '')

    If @mode IN ('add', 'check_add') AND (@status = 'Completed' OR @status = '')
        Set @status = 'Active'
    --
    If @mode IN ('add', 'check_add') AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
        RAISERROR ('Status "%s" is not valid; must be Active, Inactive, or Completed', 11, 37, @status)
    --
    If @mode IN ('update', 'check_update') AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
        RAISERROR ('Status "%s" is not valid; must be Active, Inactive, or Completed', 11, 38, @status)
    --
    If @mode IN ('update', 'check_update') AND (@status = 'Completed' AND @oldStatus <> 'Completed' )
    Begin
        Set @msg = 'Cannot set status of request to "Completed" when existing status is "' + @oldStatus + '"'
        RAISERROR (@msg, 11, 39)
    End
    --
    If @mode IN ('update', 'check_update') AND (@oldStatus = 'Completed' AND @status <> 'Completed')
        RAISERROR ('Cannot change status of a request that has been consumed by a dataset', 11, 40)

    If IsNull(@wellplate, '') IN ('', 'na')
        Set @wellplate = null

    If IsNull(@wellNum, '') IN ('', 'na')
        Set @wellNum = null

    Declare @statusID int = 0

    SELECT @statusID = State_ID
    FROM T_Requested_Run_State_Name
    WHERE (State_Name = @status)

    ---------------------------------------------------
    -- Get experiment ID from experiment number
    -- (and validate that it exists in database)
    -- Also set wellplate and well from experiment
    -- if called for
    ---------------------------------------------------

    Declare @experimentID int = 0

    SELECT
        @experimentID = Exp_ID,
        @wellplate = CASE WHEN @wellplate = '(lookup)' THEN EX_wellplate_num ELSE @wellplate END,
        @wellNum =  CASE WHEN @wellNum = '(lookup)' THEN EX_well_num ELSE @wellNum END
    FROM T_Experiments
    WHERE Experiment_Num = @experimentNum
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error looking up experiment', 11, 17)
    --
    If @experimentID = 0
        RAISERROR ('Could not find entry in database for experiment "%s"', 11, 18, @experimentNum)

    ---------------------------------------------------
    -- verify user ID for operator PRN
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call GetUserID for ' + @requesterPRN
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    Declare @userID int
    execute @userID = GetUserID @requesterPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @requesterPRN contains simply the username
        --
        SELECT @requesterPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @requesterPRN
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newPRN varchar(64)

        exec AutoResolveNameToPRN @requesterPRN, @matchCount output, @newPRN output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @requesterPRN
            Set @requesterPRN = @newPRN
        End
        Else
        Begin
            RAISERROR ('Could not find entry in database for requester username "%s"', 11, 19, @requesterPRN)
            return 51019
        End
    End

    ---------------------------------------------------
    -- Lookup instrument run info fields
    -- (only effective for experiments that have associated sample prep requests)
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'LookupInstrumentRunInfoFromExperimentSamplePrep for ' + @experimentNum
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    exec @myError = LookupInstrumentRunInfoFromExperimentSamplePrep
                        @experimentNum,
                        @instrumentGroup output,
                        @msType output,
                        @instrumentSettings output,
                        @separationGroup output,
                        @msg output
    If @myError <> 0
        RAISERROR ('LookupInstrumentRunInfoFromExperimentSamplePrep: %s', 11, 1, @msg)


    ---------------------------------------------------
    -- Determine the Instrument Group
    ---------------------------------------------------

    If NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @instrumentGroup)
    Begin
        -- Try to update instrument group using T_Instrument_Name
        SELECT @instrumentGroup = IN_Group
        FROM T_Instrument_Name
        WHERE IN_Name = @instrumentGroup
    End

    ---------------------------------------------------
    -- Validate instrument group and dataset type
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'ValidateInstrumentGroupAndDatasetType for ' + @msType
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    Declare @datasetTypeID int
    --
    exec @myError = ValidateInstrumentGroupAndDatasetType
                            @msType,
                            @instrumentGroup output,
                            @datasetTypeID output,
                            @msg output
    If @myError <> 0
        RAISERROR ('ValidateInstrumentGroupAndDatasetType: %s', 11, 1, @msg)

    ---------------------------------------------------
    -- Resolve ID for @separationGroup
    -- First look in T_Separation_Group
    ---------------------------------------------------
    --
    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Resolve separation group: ' + @separationGroup
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    Declare @sepID int = 0
    Declare @matchedSeparationGroup varchar(64) = ''

    SELECT @matchedSeparationGroup = Sep_Group
    FROM T_Separation_Group
    WHERE Sep_Group = @separationGroup

    If IsNull(@matchedSeparationGroup, '') <> ''
        Set @separationGroup = @matchedSeparationGroup
    Else
    Begin
        -- Match not found; try T_Secondary_Sep
        --
        SELECT @sepID = SS_ID, @matchedSeparationGroup = Sep_Group
        FROM T_Secondary_Sep
        WHERE SS_name = @separationGroup
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to look up separation type ID', 11, 98)
        --
        If @sepID = 0
            RAISERROR ('Separation group not recognized', 11, 99)

        If IsNull(@matchedSeparationGroup, '') <> ''
        Begin
            -- Auto-update @separationGroup to be @matchedSeparationGroup
            Set @separationGroup = @matchedSeparationGroup
        End
    End

    ---------------------------------------------------
    -- Resolve ID for MRM attachment
    ---------------------------------------------------
    --
    Declare @mrmAttachmentID int
    --
    Set @mrmAttachment = ISNULL(@mrmAttachment, '')
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
    -- This will update the data in @eusUsageType, @eusProposalID, or @eusUsersList if it is "(lookup)"
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Lookup EUS info for: ' + @experimentNum
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End
    --
    exec @myError = LookupEUSFromExperimentSamplePrep
                        @experimentNum,
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUsersList output,
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
            'user list ' + IsNull(@eusUsersList, '?Null?')

        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    -- Note that if @eusUsersList contains a list of names in the form "Baker, Erin (41136)",
    -- ValidateEUSUsage will change this into a list of EUS user IDs (integers)

    If Len(@eusUsersList) = 0 And @autoPopulateUserListIfBlank > 0
    Begin
        Set @raiseErrorOnMultipleEUSUsers = 0
    End

    Declare @eusUsageTypeID Int

    Declare @addingItem tinyint = 0
    If @mode IN ('add', 'check_add')
    Begin
        Set @addingItem = 1
    End

    exec @myError = ValidateEUSUsage
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUsersList output,
                        @eusUsageTypeID output,
                        @msg output,
                        @autoPopulateUserListIfBlank,
                        @samplePrepRequest = 0,
                        @experimentID = @experimentID,
                        @campaignID = 0,
                        @addingItem = @addingItem


    If @myError <> 0
        RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

    If @eusUsageTypeID = 1
    Begin
        RAISERROR ('EUS Usage Type cannot be "undefined" for requested runs', 11, 1)
    End

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
    End

    Declare @commaPosition Int = CharIndex(',', @eusUsersList)
    If @commaPosition > 1
    Begin
        Set @message = dbo.AppendToText('Requested runs can only have a single EUS user associated with them', @message, 0, '; ', 1024)

        If @raiseErrorOnMultipleEUSUsers > 0
            RAISERROR ('ValidateEUSUsage: %s', 11, 1, @message)

        -- Only keep the first user
        Set @eusUsersList = Left(@eusUsersList, @commaPosition - 1)
    End

    ---------------------------------------------------
    -- Lookup misc fields (only applies to experiments with sample prep requests)
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Lookup misc fields for the experiment'
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    exec @myError = LookupOtherFromExperimentSamplePrep
                        @experimentNum,
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
    -- Validate the batch ID
    ---------------------------------------------------

    If Not Exists (Select * FROM T_Requested_Run_Batches Where ID = @batch)
    Begin
        If @mode Like '%update%'
            Set @mode = 'update'
        Else
            Set @mode = 'add'

        RAISERROR ('Cannot %s: Batch ID "%d" is not in the database', 11, 4, @mode, @batch)
    End

    ---------------------------------------------------
    -- Validate the work package
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Validate the WP'
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
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

    If @status <> 'Active' And (@eusUsageType = 'Maintenance' Or @reqName Like 'AutoReq[_]%')
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
            Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackage + ' is deactivated', 0, '; ', 1024)
        Else
        Begin
            If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Charge_Code_State = 0)
                Set @message = dbo.AppendToText(@message, 'Warning: Work Package ' + @workPackage + ' is likely deactivated', 0, '; ', 1024)
        End
    End

    Set @resolvedInstrumentInfo = 'instrument group ' + @instrumentGroup + ', run type ' + @msType + ', and separation group ' + @separationGroup

    -- Validation checks are complete; now enable @logErrors
    Set @logErrors = 1

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Start a new transaction'
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------
    Declare @transName varchar(256) = 'AddUpdateRequestedRun_' + @reqName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin -- <add>

        -- Start transaction
        --
        Begin transaction @transName

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
            RDS_Well_Plate_Num,
            RDS_Well_Num,
            RDS_internal_standard,
            RDS_BatchID,
            RDS_Block,
            RDS_Run_Order,
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
            @reqName,
            @requesterPRN,
            @comment,
            GETDATE(),
            @instrumentGroup,
            @datasetTypeID,
            @instrumentSettings,
            @defaultPriority, -- priority
            @experimentID,
            @workPackage,
            @wellplate,
            @wellNum,
            @internalStandard,
            @batch,
            @block,
            @runOrder,
            @eusProposalID,
            @eusUsageTypeID,
            @separationGroup,
            @mrmAttachmentID,
            @requestOrigin,
            @status,
            @vialingConc,
            @vialingVol,
            @locationId
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed: "%s"', 11, 7, @reqName)

        Set @request = SCOPE_IDENTITY()

        -- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec AlterEventLogEntryUser 11, @request, @statusID, @callingUser
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call AssignEUSUsersToRequestedRun'
            exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
        End

        -- assign users to the request
        --
        exec @myError = AssignEUSUsersToRequestedRun
                                @request,
                                @eusProposalID,
                                @eusUsersList,
                                @msg output
        --
        If @myError <> 0
            RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 19, @msg)

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            exec PostLogEntry 'Error', @debugMsg, 'AddUpdateRequestedRun'
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Transaction committed'
            exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateRequestedRun'
        End

        If @status = 'Active'
        Begin
            -- Add a new row to T_Active_Requested_Run_Cached_EUS_Users
            exec UpdateCachedRequestedRunEUSUsers @request
        End

    End -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin -- <update>

        SELECT @currentBatch = RDS_BatchID
        FROM T_Requested_Run
        WHERE ID = @requestID

        Begin transaction @transName

        Set @myError = 0
        --
        UPDATE T_Requested_Run
        SET
            RDS_Name = CASE WHEN @requestIDForUpdate > 0 THEN @reqName ELSE RDS_Name END,
            RDS_Requestor_PRN = @requesterPRN,
            RDS_comment = @comment,
            RDS_instrument_group = @instrumentGroup,
            RDS_type_ID = @datasetTypeID,
            RDS_instrument_setting = @instrumentSettings,
            Exp_ID = @experimentID,
            RDS_WorkPackage = @workPackage,
            RDS_Well_Plate_Num = @wellplate,
            RDS_Well_Num = @wellNum,
            RDS_internal_standard = @internalStandard,
            RDS_BatchID = @batch,
            RDS_Block = @block,
            RDS_Run_Order = @runOrder,
            RDS_EUS_Proposal_ID = @eusProposalID,
            RDS_EUS_UsageType = @eusUsageTypeID,
            RDS_Sec_Sep = @separationGroup,
            RDS_MRM_Attachment = @mrmAttachmentID,
            RDS_Status = @status,
            RDS_created = CASE WHEN @oldStatus = 'Inactive' AND @status = 'Active' THEN GETDATE() ELSE RDS_created END,
            Vialing_Conc = @vialingConc,
            Vialing_Vol = @vialingVol,
            Location_Id = @locationId
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @reqName)

        -- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec AlterEventLogEntryUser 11, @requestID, @statusID, @callingUser
        End

        -- assign users to the request
        --
        exec @myError = AssignEUSUsersToRequestedRun
                                @requestID,
                                @eusProposalID,
                                @eusUsersList,
                                @msg output
        --
        If @myError <> 0
            RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 20, @msg)

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            exec PostLogEntry 'Error', @debugMsg, 'AddUpdateRequestedRun'
        End

        -- Make sure that T_Active_Requested_Run_Cached_EUS_Users is up-to-date
        exec UpdateCachedRequestedRunEUSUsers @request

        If @batch = 0 And @currentBatch <> 0
        Begin
            Set @msg = 'Removed request ' + Cast(@request As Varchar(12)) + ' from batch ' + Cast(@currentBatch As Varchar(12))
            Set @message = dbo.AppendToText(@message, @msg, 0, '; ', 1024)
        End
    End -- </update>

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If @batch > 0
    Begin
        Exec UpdateCachedRequestedRunBatchStats @batch
    End

    If @currentBatch > 0
    Begin
        Exec UpdateCachedRequestedRunBatchStats @currentBatch
    End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0 And IsNull(@skipTransactionRollback, 0) = 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1500) = @message + '; Req Name ' + @reqName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateRequestedRun'
        End

    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
