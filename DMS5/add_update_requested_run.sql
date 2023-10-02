/****** Object:  StoredProcedure [dbo].[add_update_requested_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_requested_run]
/****************************************************
**
**  Desc:
**      Adds a new entry to the requested dataset table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/11/2002 grk - Initial version
**          02/15/2003 grk
**          12/05/2003 grk - Added wellplate stuff
**          01/05/2004 grk - Added internal standard stuff
**          03/01/2004 grk - Added manual identity calculation (removed identity column)
**          03/10/2004 grk - Repaired manual identity calculation to include history table
**          07/15/2004 grk - Added verification of experiment location aux info
**          11/26/2004 grk - Changed type of @comment from text to varchar
**          01/12/2004 grk - Fixed null return on check existing when table is empty
**          10/12/2005 grk - Added stuff for new work package and proposal fields.
**          02/21/2006 grk - Added stuff for EUS proposal and user tracking.
**          11/09/2006 grk - Fixed error message handling (Ticket #318)
**          01/12/2007 grk - Added verification mode
**          01/31/2007 grk - Added verification for @requestorUsername (Ticket #371)
**          03/19/2007 grk - Added @defaultPriority (Ticket #421) (set it back to 0 on 04/25/2007)
**          04/25/2007 grk - Get new ID from UDF (Ticket #446)
**          04/30/2007 grk - Added better name validation (Ticket #450)
**          07/11/2007 grk - Factored out EUS proposal validation (Ticket #499)
**          07/11/2007 grk - Modified to look up EUS fields from sample prep request (Ticket #499)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          07/30/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - Factored out instrument name and dataset type validation to ValidateInstrumentAndDatasetType (Ticket #512)
**          09/06/2007 grk - Added call to lookup_instrument_run_info_from_experiment_sample_prep (Ticket #512)
**          09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**          04/09/2008 grk - Added secondary separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          06/03/2009 grk - Look up work package (Ticket #739)
**          07/27/2009 grk - Added lookup for wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          02/28/2010 grk - Added add-auto mode
**          03/02/2010 grk - Added status field to requested run
**          03/10/2010 grk - Fixed issue with status validation
**          03/27/2010 grk - Fixed problem creating new requests with "Completed" status.
**          04/20/2010 grk - Fixed problem with experiment lookup validation
**          04/21/2010 grk - Try-catch for error handling
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if @requestorUsername contains a person's real name rather than their username
**          08/27/2010 mem - Now auto-switching @instrumentName to be instrument group instead of instrument name
**          09/01/2010 mem - Added parameter @SkipTransactionRollback
**          09/09/2010 mem - Added parameter @autoPopulateUserListIfBlank
**          07/29/2011 mem - Now querying T_Requested_Run with both @requestName and @status when the mode is update or check_update
**          11/29/2011 mem - Tweaked warning messages when checking for existing request
**          12/05/2011 mem - Updated @transName to use a custom transaction name
**          12/12/2011 mem - Updated call to validate_eus_usage to treat @eusUsageType as an input/output parameter
**                         - Added parameter @callingUser, which is passed to alter_event_log_entry_user
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**          01/09/2012 grk - Added @secSep to lookup_instrument_run_info_from_experiment_sample_prep
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
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Add parameter @logDebugMessages
**          02/07/2017 mem - Change default for @logDebugMessages to 0
**          06/13/2017 mem - Rename @operUsername to @requestorUsername
**                         - Make sure the Work Package is capitalized properly
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/12/2017 mem - Add @stagingLocation (points to T_Material_Locations)
**          06/12/2018 mem - Send @maxLength to append_to_text
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          09/03/2018 mem - Apply a maximum length restriction of 64 characters to @requestName when creating a new requested run
**          12/10/2018 mem - Report an error if the comment contains 'experiment_group/show/0000'
**          07/01/2019 mem - Allow @workPackage to be none if the Request is not active and either the Usage Type is Maintenance or the name starts with "AutoReq_"
**          02/03/2020 mem - Raise an error if @eusUsersList contains multiple user IDs (since ERS only allows for a single user to be associated with a dataset)
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use replace_character_codes to replace character codes with punctuation marks
**                         - Use remove_cr_lf to replace linefeeds with semicolons
**          05/25/2021 mem - Append new messages to @message (including from lookup_eus_from_experiment_sample_prep)
**                         - Expand @message to varchar(1024)
**          05/26/2021 mem - Check for undefined EUS Usage Type (ID = 1)
**                     bcg - Bug fix: use @eusUsageTypeID to prevent use of EUS Usage Type "Undefined"
**                     mem - When @mode is 'add', 'add-auto', or 'check_add', possibly override the EUSUsageType based on the campaign's EUS Usage Type
**          05/27/2021 mem - Refactor EUS Usage validation code into validate_eus_usage
**          05/31/2021 mem - Add output parameter @resolvedInstrumentInfo
**          06/01/2021 mem - Update the message stored in @resolvedInstrumentInfo
**          10/06/2021 mem - Add @batch, @block, and @runOrder
**          02/17/2022 mem - Update requestor username warning
**          05/23/2022 mem - Rename requester username argument and update username warning
**          11/25/2022 mem - Rename parameter to @wellplateName
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          10/02/2023 mem - Use @requestID when calling update_cached_requested_run_eus_users
**
*****************************************************/
(
    @requestName varchar(128),
    @experimentName varchar(64),
    @requesterUsername varchar(64),
    @instrumentName varchar(64),                -- Instrument group; could also contain "(lookup)"
    @workPackage varchar(50),                   -- Work package; could also contain "(lookup)".  May contain 'none' for automatically created requested runs (and those will have @autoPopulateUserListIfBlank=1)
    @msType varchar(20),
    @instrumentSettings varchar(512) = 'na',
    @wellplateName varchar(64) = 'na',          -- Wellplate name
    @wellNumber varchar(24) = 'na',
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
    @skipTransactionRollback tinyint = 0,       -- This is set to 1 when stored procedure add_update_dataset calls this stored procedure
    @autoPopulateUserListIfBlank tinyint = 0,   -- When 1, will auto-populate @eusUsersList if it is empty and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
    @callingUser varchar(128) = '',
    @vialingConc varchar(32) = null,
    @vialingVol varchar(32) = null,
    @stagingLocation varchar(64) = null,
    @requestIDForUpdate int = null,             -- Only used if @mode is 'update' or 'check_update' and only used if not 0 or null.  Can be used to rename an existing request
    @logDebugMessages tinyint = 0,
    @resolvedInstrumentInfo varchar(256) = '' output      -- Output parameter that lists the the instrument group, run type, and separation group; used by add_requested_runs when previewing updates
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
    Exec @authorized = verify_sp_authorized 'add_update_requested_run', @raiseError = 1
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
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    If IsNull(@requestName, '') = ''
        RAISERROR ('Request name must be specified', 11, 110)
    --
    If IsNull(@experimentName, '') = ''
        RAISERROR ('Experiment number must be specified', 11, 111)
    --
    If IsNull(@requesterUsername, '') = ''
        RAISERROR ('Requester username must be specified', 11, 113)
    --
    Declare @instrumentGroup varchar(64) = @instrumentName
    If IsNull(@instrumentGroup, '') = ''
        RAISERROR ('Instrument group must be specified', 11, 114)
    --
    If IsNull(@msType, '') = ''
        RAISERROR ('Dataset type must be specified', 11, 115)
    --
    If IsNull(@workPackage, '') = ''
        RAISERROR ('Work package must be specified', 11, 116)

    Set @requestIDForUpdate = IsNull(@requestIDForUpdate, 0)

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.replace_character_codes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.remove_cr_lf(@comment)

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

    Declare @badCh varchar(128) = dbo.validate_chars(@requestName, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            RAISERROR ('Requested run name may not contain spaces', 11, 1)
        Else
            RAISERROR ('Requested run name may not contain the character(s) "%s"', 11, 1, @badCh)
    End

    Set @requestName = Ltrim(Rtrim(@requestName))

    Declare @nameLength int = Len(@requestName)

    If @nameLength > 64 And @mode IN ('add', 'check_add') And @requestOrigin <> 'auto'
    Begin
        RAISERROR ('Requested run name is too long (%d characters); max length is 64 characters', 11, 2, @nameLength)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    -- Note that if a request is recycled, the old and new requests
    --  will have the same name but different IDs
    -- When @mode is Update, we should first look for an existing request
    --  with name @requestName and status @status
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

            If @oldReqName <> @requestName
            Begin
                If @status <> 'Active'
                    RAISERROR ('Requested run is not active; cannot rename: "%s"', 11, 7, @oldReqName)

                If Exists (Select * from T_Requested_Run Where RDS_Name = @requestName)
                    RAISERROR ('Cannot rename "%s" since new name already exists: "%s"', 11, 7, @oldReqName, @requestName)
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
            WHERE RDS_Name = @requestName AND
                  RDS_Status = @status
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error trying to find existing request: "%s"', 11, 7, @requestName)

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
        WHERE RDS_Name = @requestName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to find existing request: "%s"', 11, 7, @requestName)
    End

    -- Need non-null request even if we are just checking
    --
    Set @request = @requestID

    -- Cannot create an entry that already exists
    --
    If @requestID <> 0 and (@mode IN ('add', 'check_add'))
        RAISERROR ('Cannot add: Requested Run "%s" already in the database; cannot add', 11, 4, @requestName)

    -- Cannot update a non-existent entry
    --
    If @requestID = 0 and (@mode IN ('update', 'check_update'))
    Begin
        If @requestIDForUpdate > 0
            RAISERROR ('Cannot update: Requested Run ID "%d" is not in the database; cannot update', 11, 4, @requestIDForUpdate)
        Else
            RAISERROR ('Cannot update: Requested Run "%s" is not in the database; cannot update', 11, 4, @requestName)
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

    If IsNull(@wellplateName, '') IN ('', 'na')
        Set @wellplateName = null

    If IsNull(@wellNumber, '') IN ('', 'na')
        Set @wellNumber = null

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
        @wellplateName = CASE WHEN @wellplateName = '(lookup)' THEN EX_wellplate_num ELSE @wellplateName END,
        @wellNumber =  CASE WHEN @wellNumber = '(lookup)' THEN EX_well_num ELSE @wellNumber END
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error looking up experiment', 11, 17)
    --
    If @experimentID = 0
        RAISERROR ('Could not find entry in database for experiment "%s"', 11, 18, @experimentName)

    ---------------------------------------------------
    -- verify user ID for operator username
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call get_user_id for ' + @requesterUsername
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    Declare @userID int
    execute @userID = get_user_id @requesterUsername

    If @userID > 0
    Begin
        -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @requesterUsername contains simply the username
        --
        SELECT @requesterUsername = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for username @requesterUsername
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newUsername varchar(64)

        Exec auto_resolve_name_to_username @requesterUsername, @matchCount output, @newUsername output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @requesterUsername
            Set @requesterUsername = @newUsername
        End
        Else
        Begin
            RAISERROR ('Could not find entry in database for requester username "%s"', 11, 19, @requesterUsername)
            return 51019
        End
    End

    ---------------------------------------------------
    -- Lookup instrument run info fields
    -- (only effective for experiments that have associated sample prep requests)
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'lookup_instrument_run_info_from_experiment_sample_prep for ' + @experimentName
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    Exec @myError = lookup_instrument_run_info_from_experiment_sample_prep
                        @experimentName,
                        @instrumentGroup output,
                        @msType output,
                        @instrumentSettings output,
                        @separationGroup output,
                        @msg output
    If @myError <> 0
        RAISERROR ('lookup_instrument_run_info_from_experiment_sample_prep: %s', 11, 1, @msg)


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
        Set @debugMsg = 'validate_instrument_group_and_dataset_type for ' + @msType
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    Declare @datasetTypeID int
    --
    Exec @myError = validate_instrument_group_and_dataset_type
                            @msType,
                            @instrumentGroup output,
                            @datasetTypeID output,
                            @msg output
    If @myError <> 0
        RAISERROR ('validate_instrument_group_and_dataset_type: %s', 11, 1, @msg)

    ---------------------------------------------------
    -- Resolve ID for @separationGroup
    -- First look in T_Separation_Group
    ---------------------------------------------------
    --
    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Resolve separation group: ' + @separationGroup
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
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
        Set @debugMsg = 'Lookup EUS info for: ' + @experimentName
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End
    --
    Exec @myError = lookup_eus_from_experiment_sample_prep
                        @experimentName,
                        @eusUsageType output,
                        @eusProposalID output,
                        @eusUsersList output,
                        @msg output

    If @myError <> 0
        RAISERROR ('lookup_eus_from_experiment_sample_prep: %s', 11, 1, @msg)

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
    End

    ---------------------------------------------------
    -- Validate EUS type, proposal, and user list
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call validate_eus_usage with ' +
            'type ' + IsNull(@eusUsageType, '?Null?') + ', ' +
            'proposal ' + IsNull(@eusProposalID, '?Null?') + ', and ' +
            'user list ' + IsNull(@eusUsersList, '?Null?')

        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    -- Note that if @eusUsersList contains a list of names in the form "Baker, Erin (41136)",
    -- validate_eus_usage will change this into a list of EUS user IDs (integers)

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

    Exec @myError = validate_eus_usage
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
        RAISERROR ('validate_eus_usage: %s', 11, 1, @msg)

    If @eusUsageTypeID = 1
    Begin
        RAISERROR ('EUS Usage Type cannot be "undefined" for requested runs', 11, 1)
    End

    If IsNull(@msg, '') <> ''
    Begin
        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
    End

    Declare @commaPosition Int = CharIndex(',', @eusUsersList)
    If @commaPosition > 1
    Begin
        Set @message = dbo.append_to_text('Requested runs can only have a single EUS user associated with them', @message, 0, '; ', 1024)

        If @raiseErrorOnMultipleEUSUsers > 0
            RAISERROR ('validate_eus_usage: %s', 11, 1, @message)

        -- Only keep the first user
        Set @eusUsersList = Left(@eusUsersList, @commaPosition - 1)
    End

    ---------------------------------------------------
    -- Lookup misc fields (only applies to experiments with sample prep requests)
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Lookup misc fields for the experiment'
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    Exec @myError = lookup_other_from_experiment_sample_prep
                        @experimentName,
                        @workPackage output,
                        @msg output

    If @myError <> 0
        RAISERROR ('lookup_other_from_experiment_sample_prep: %s', 11, 1, @msg)

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
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
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

    If @status <> 'Active' And (@eusUsageType = 'Maintenance' Or @requestName Like 'AutoReq[_]%')
    Begin
        Set @allowNoneWP = 1
    End

    Exec @myError = validate_wp
                        @workPackage,
                        @allowNoneWP,
                        @msg output

    If @myError <> 0
        RAISERROR ('validate_wp: %s', 11, 1, @msg)

    -- Make sure the Work Package is capitalized properly
    --
    SELECT @workPackage = Charge_Code
    FROM T_Charge_Code
    WHERE Charge_Code = @workPackage

    If @autoPopulateUserListIfBlank = 0
    Begin
        If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Deactivated = 'Y')
            Set @message = dbo.append_to_text(@message, 'Warning: Work Package ' + @workPackage + ' is deactivated', 0, '; ', 1024)
        Else
        Begin
            If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Charge_Code_State = 0)
                Set @message = dbo.append_to_text(@message, 'Warning: Work Package ' + @workPackage + ' is likely deactivated', 0, '; ', 1024)
        End
    End

    Set @resolvedInstrumentInfo = 'instrument group ' + @instrumentGroup + ', run type ' + @msType + ', and separation group ' + @separationGroup

    -- Validation checks are complete; now enable @logErrors
    Set @logErrors = 1

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Start a new transaction'
        Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------
    Declare @transName varchar(256) = 'add_update_requested_run_' + @requestName

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
            @requestName,
            @requesterUsername,
            @comment,
            GETDATE(),
            @instrumentGroup,
            @datasetTypeID,
            @instrumentSettings,
            @defaultPriority, -- priority
            @experimentID,
            @workPackage,
            @wellplateName,
            @wellNumber,
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
            RAISERROR ('Insert operation failed: "%s"', 11, 7, @requestName)

        Set @request = SCOPE_IDENTITY()

        Set @requestID = @request

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec alter_event_log_entry_user 11, @requestID, @statusID, @callingUser
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call assign_eus_users_to_requested_run'
            Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
        End

        -- assign users to the request
        --
        Exec @myError = assign_eus_users_to_requested_run
                                @requestID,
                                @eusProposalID,
                                @eusUsersList,
                                @msg output
        --
        If @myError <> 0
            RAISERROR ('assign_eus_users_to_requested_run: %s', 11, 19, @msg)

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            Exec post_log_entry 'Error', @debugMsg, 'add_update_requested_run'
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Transaction committed'
            Exec post_log_entry 'Debug', @debugMsg, 'add_update_requested_run'
        End

        If @status = 'Active'
        Begin
            -- Add a new row to T_Active_Requested_Run_Cached_EUS_Users
            Exec update_cached_requested_run_eus_users @requestID
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
            RDS_Name = CASE WHEN @requestIDForUpdate > 0 THEN @requestName ELSE RDS_Name END,
            RDS_Requestor_PRN = @requesterUsername,
            RDS_comment = @comment,
            RDS_instrument_group = @instrumentGroup,
            RDS_type_ID = @datasetTypeID,
            RDS_instrument_setting = @instrumentSettings,
            Exp_ID = @experimentID,
            RDS_WorkPackage = @workPackage,
            RDS_Well_Plate_Num = @wellplateName,
            RDS_Well_Num = @wellNumber,
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
            RAISERROR ('Update operation failed: "%s"', 11, 4, @requestName)

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec alter_event_log_entry_user 11, @requestID, @statusID, @callingUser
        End

        -- assign users to the request
        --
        Exec @myError = assign_eus_users_to_requested_run
                                @requestID,
                                @eusProposalID,
                                @eusUsersList,
                                @msg output
        --
        If @myError <> 0
            RAISERROR ('assign_eus_users_to_requested_run: %s', 11, 20, @msg)

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            Exec post_log_entry 'Error', @debugMsg, 'add_update_requested_run'
        End

        -- Make sure that T_Active_Requested_Run_Cached_EUS_Users is up-to-date
        Exec update_cached_requested_run_eus_users @requestID

        If @batch = 0 And @currentBatch <> 0
        Begin
            Set @msg = 'Removed request ' + Cast(@requestID As Varchar(12)) + ' from batch ' + Cast(@currentBatch As Varchar(12))
            Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
        End
    End -- </update>

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If @batch > 0
    Begin
        Exec update_cached_requested_run_batch_stats @batch
    End

    If @currentBatch > 0
    Begin
        Exec update_cached_requested_run_batch_stats @currentBatch
    End

    END TRY
    BEGIN CATCH
        Exec format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0 And IsNull(@skipTransactionRollback, 0) = 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1500) = @message + '; Req Name ' + @requestName
            Exec post_log_entry 'Error', @logMessage, 'add_update_requested_run'
        End

    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_requested_run] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_requested_run] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_requested_run] TO [Limited_Table_Write] AS [dbo]
GO
