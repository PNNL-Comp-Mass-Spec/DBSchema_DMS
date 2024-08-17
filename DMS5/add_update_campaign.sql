/****** Object:  StoredProcedure [dbo].[add_update_campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_campaign]
/****************************************************
**
**  Desc:
**      Adds new or updates existing campaign in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/08/2002
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          01/15/2010 grk - Added new fields (http://prismtrac.pnl.gov/trac/ticket/753)
**          02/05/2010 grk - Split team member field
**          02/07/2010 grk - Added validation for campaign name
**          02/07/2010 mem - No longer validating @progmgrUsername or @piUsername in this procedure since this is now handled by update_research_team_for_campaign
**          03/17/2010 grk - Data release restrictions (Ticket http://prismtrac.pnl.gov/trac/ticket/758)
**          04/21/2010 grk - try-catch for error handling
**          10/27/2011 mem - Added parameter @fractionEMSLFunded
**          12/01/2011 mem - Updated @fractionEMSLFunded to be a required value
**                         - Now calling alter_event_log_entry_user for updates to CM_Fraction_EMSL_Funded or CM_Data_Release_Restrictions
**          10/23/2012 mem - Now validating that @fractionEMSLFunded is a number between 0 and 1 using a real (since conversion of 100 to Decimal(3, 2) causes an overflow error)
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on\
**          02/26/2016 mem - Define a default for @fractionEMSLFunded
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Tweak error messages
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the campaign name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Disable logging when the campaign name has invalid characters
**          06/14/2017 mem - Allow @fractionEMSLFundedValue to be empty
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          05/26/2021 mem - Add @eusUsageType
**          09/29/2021 mem - Assure that EUS Usage Type is 'USER_ONSITE' if associated with a Resource Owner proposal
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/16/2022 mem - Fix potential arithmetic overflow error when parsing @fractionEMSLFunded
**          02/13/2023 bcg - Rename parameters to @progmgrUsername and @piUsername
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          11/01/2023 mem - Remove unreachable code when validating campaign name
**          01/04/2024 mem - Rename parameter to @dataReleaseRestriction and use new data release restriction column name in T_Campaign
**
*****************************************************/
(
    @campaignName varchar(64),              -- Campaign name
    @projectName varchar(64),               -- Project name
    @progmgrUsername varchar(64),           -- Project Manager Username (required)
    @piUsername varchar(64),                -- Principal Investigator Username (required)
    @technicalLead varchar(256),            -- Technical Lead
    @samplePreparationStaff varchar(256),   -- Sample Prep Staff
    @datasetAcquisitionStaff varchar(256),  -- Dataset acquisition staff
    @informaticsStaff varchar(256),         -- Informatics staff
    @collaborators varchar(256),            -- Collaborators
    @comment varchar(500),
    @state varchar(24),
    @description varchar(512),
    @externalLinks varchar(512),
    @eprList varchar(256),
    @eusProposalList varchar(256),
    @organisms varchar(256),
    @experimentPrefixes varchar(256),
    @dataReleaseRestriction varchar(128),
    @fractionEMSLFunded varchar(24) = '0',  -- Value between 0 and 1
    @eusUsageType varchar(50) = 'USER_ONSITE',
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)

    Declare @stateID int
    Declare @eusUsageTypeID int = 0
    Declare @eusUsageTypeEnabled Tinyint = 0
    Declare @proposalType varchar(100)

    Declare @percentEMSLFunded int

    Declare @fractionEMSLFundedValue real = 0
    Declare @fractionEMSLFundedToStore decimal(3, 2) = 0

    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_campaign', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @campaignName = LTrim(RTrim(IsNull(@campaignName, '')))
    Set @projectName = LTrim(RTrim(IsNull(@projectName, '')))
    Set @progmgrUsername = LTrim(RTrim(IsNull(@progmgrUsername, '')))
    Set @piUsername = LTrim(RTrim(IsNull(@piUsername, '')))

    Set @myError = 0
    If LEN(@campaignName) < 1
        RAISERROR ('Campaign name must be specified', 11, 1)
    --
    If LEN(@projectName) < 1
        RAISERROR ('Project name must be specified', 11, 1)
    --
    If LEN(@progmgrUsername) < 1
        RAISERROR ('Project Manager username must be specified', 11, 2)
    --
    If LEN(@piUsername) < 1
        RAISERROR ('Principle Investigator username must be specified', 11, 3)

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @campaignID int = 0
    Declare @researchTeamID INT = 0
    --
    SELECT @campaignID = Campaign_ID,
           @researchTeamID = ISNULL(CM_Research_Team, 0)
    FROM T_Campaign
    WHERE Campaign_Num = @campaignName

    -- Cannot create an entry that already exists
    --
    If @campaignID <> 0 and @mode = 'add'
        RAISERROR ('Cannot add: Campaign "%s" already in database', 11, 4, @campaignName)

    -- Cannot update a non-existent entry
    --
    If @campaignID = 0 and @mode = 'update'
        RAISERROR ('Cannot update: Campaign "%s" is not in database', 11, 5, @campaignName)

    ---------------------------------------------------
    -- Resolve data release restriction name to ID
    ---------------------------------------------------
    --
    Declare @dataReleaseRestrictionID int = -1
    --
    SELECT @dataReleaseRestrictionID = ID
    FROM T_Data_Release_Restrictions
    WHERE Name = @dataReleaseRestriction
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error resolving data release restriction', 11, 6)
    --
    If @dataReleaseRestrictionID < 0
        RAISERROR ('Could not resolve data release restriction; please select a valid entry from the list', 11, 7)

    ---------------------------------------------------
    -- Validate Fraction EMSL Funded
    -- If @fractionEMSLFunded is empty we treat it as a Null value
    ---------------------------------------------------
    --

    Set @fractionEMSLFunded = IsNull(@fractionEMSLFunded, '')
    If Len(@fractionEMSLFunded) > 0
    Begin
        Set @fractionEMSLFundedValue = Try_Parse(@fractionEMSLFunded as real)

        If @fractionEMSLFundedValue Is Null
        Begin
            RAISERROR ('Fraction EMSL Funded must be a number between 0 and 1', 11, 4)
        End

        If @fractionEMSLFundedValue > 1
        Begin
            Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @fractionEMSLFunded + ' is greater than 1)'
            RAISERROR (@msg, 11, 4)
        End

        If @fractionEMSLFundedValue < 0
        Begin
            Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @fractionEMSLFunded + ' is less than 0)'
            RAISERROR (@msg, 11, 4)
        End

        Set @fractionEMSLFundedToStore = Convert(decimal(3, 2), @fractionEMSLFunded)

    End
    Else
    Begin
        Set @fractionEMSLFundedToStore = 0
    End

    ---------------------------------------------------
    -- Validate campaign name
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        Declare @badCh varchar(128) = dbo.validate_chars(@campaignName, '')

        -- Campaign names can have spaces, so remove '[space]' from @badCh if present
        Set @badCh = REPLACE(@badCh, '[space]', '')

        If @badCh <> ''
        Begin
            RAISERROR ('Campaign name may not contain the character(s) "%s"', 11, 9, @badCh)
        End
    End

    ---------------------------------------------------
    -- Validate EUS Usage Type
    ---------------------------------------------------
    --

    Set @eusUsageType = IsNull(@eusUsageType, '')

    If Len(@eusUsageType) = 0
    Begin
        Set @eusUsageType = 'USER_ONSITE'
    End

    SELECT @eusUsageTypeID = ID,
           @eusUsageTypeEnabled = Enabled_Campaign
    FROM T_EUS_UsageType
    WHERE Name = @eusUsageType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        RAISERROR ('Error trying to resolve EUS usage type: %s', 11, 4, @eusUsageType)
    End

    If @myRowCount = 0
    Begin
        RAISERROR ('Unrecognized EUS Usage Type: %s', 11, 4, @eusUsageType)
    End

    If @eusUsageTypeEnabled = 0
    Begin
        RAISERROR ('EUS Usage Type is not allowed for campaigns: %s', 11, 4, @eusUsageType)
    End

    If Len(IsNull(@eusProposalList, '')) > 0
    Begin
        If @eusUsageType = 'CAP_DEV'
        Begin
            -- CAP_DEV should not be used when one or more EUS proposals are defined for a campaign
            RAISERROR ('Please choose usage type USER_ONSITE if this campaign''s samples are for an onsite user or are for a Resource Owner project; choose USER_REMOTE if for an EMSL user', 11, 4)
        End

        -- If @eusProposalList has a single proposal, get the proposal type then validate @eusUsageType
        -- If multiple proposals are defined, the validation is skipped
        SELECT @proposalType = Proposal_Type
        FROM T_EUS_Proposals
        WHERE Proposal_ID = @eusProposalList

        If IsNull(@proposalType, '') = 'Resource Owner' And @eusUsageType In ('USER_REMOTE', '')
        Begin
            Set @eusUsageType = 'USER_ONSITE'
            Set @message = 'Auto-updated EUS usage type to USER_ONSITE since this campaign has a Resource Owner project'

            SELECT @eusUsageTypeID = ID
            FROM T_EUS_UsageType
            WHERE Name = @eusUsageType
        End
    End

    ---------------------------------------------------
    -- Validate Fraction EMSL Funded
    ---------------------------------------------------
    --
    If @fractionEMSLFundedToStore > 1
    Begin
        Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @fractionEMSLFunded + ' is greater than 1)'
        RAISERROR (@msg, 11, 4)
    End

    If @fractionEMSLFundedToStore < 0
    Begin
        Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @fractionEMSLFunded + ' is less than 0)'
        RAISERROR (@msg, 11, 4)
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Transaction name
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'add_update_campaign'

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin

        Begin transaction @transName

        ---------------------------------------------------
        -- Create research team
        ---------------------------------------------------
        --
        EXEC @myError = update_research_team_for_campaign
                            @campaignName,
                            @progmgrUsername ,
                            @piUsername,
                            @technicalLead,
                            @samplePreparationStaff,
                            @datasetAcquisitionStaff,
                            @informaticsStaff,
                            @collaborators,
                            @researchTeamID output,
                            @msg output
        --
        If @myError <> 0
        Begin
            Set @message = @msg
            RAISERROR (@message, 11, 11)
        End

        ---------------------------------------------------
        -- Create campaign
        ---------------------------------------------------
        --
        INSERT INTO T_Campaign (
            Campaign_Num,
            CM_Project_Num,
            CM_comment,
            CM_State,
            CM_Description,
            CM_External_Links,
            CM_EPR_List,
            CM_EUS_Proposal_List,
            CM_Organisms,
            CM_Experiment_Prefixes,
            CM_created,
            CM_Research_Team,
            CM_Data_Release_Restriction,
            CM_Fraction_EMSL_Funded,
            CM_EUS_Usage_Type
        ) VALUES (
            @campaignName,
            @projectName,
            @comment,
            @state,
            @description,
            @externalLinks,
            @eprList,
            @eusProposalList,
            @organisms,
            @experimentPrefixes,
            GETDATE(),
            @researchTeamID,
            @dataReleaseRestrictionID,
            @fractionEMSLFundedToStore,
            @eusUsageTypeID
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed: "%s"', 11, 12, @campaignName )

        -- Get the ID of newly created campaign
        Set @campaignID = SCOPE_IDENTITY()

        -- As a precaution, query T_Campaign using Campaign name to make sure we have the correct Campaign_ID
        Declare @idConfirm int = 0

        SELECT @idConfirm = Campaign_ID
        FROM T_Campaign
        WHERE Campaign_Num = @campaignName

        If @campaignID <> IsNull(@idConfirm, @campaignID)
        Begin
            Declare @debugMsg varchar(512)
            Set @debugMsg = 'Warning: Inconsistent identity values when adding campaign ' + @campaignName + ': Found ID ' +
                            Cast(@idConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                            Cast(@campaignID as varchar(12))

            exec post_log_entry 'Error', @debugMsg, 'add_update_campaign'

            Set @campaignID = @iDConfirm
        End

        commit transaction @transName

        Set @stateID = 1
        Set @percentEMSLFunded = CONVERT(int, @fractionEMSLFundedToStore * 100)

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec alter_event_log_entry_user 1, @campaignID, @stateID, @callingUser
            Exec alter_event_log_entry_user 9, @campaignID, @percentEMSLFunded, @callingUser
            Exec alter_event_log_entry_user 10, @campaignID, @dataReleaseRestrictionID, @callingUser
        End

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Begin transaction @transName
        --
        Set @myError = 0
        --
        ---------------------------------------------------
        -- Update campaign
        ---------------------------------------------------
        --
        UPDATE T_Campaign
        SET
            CM_Project_Num = @projectName,
            CM_comment = @comment,
            CM_State = @state,
            CM_Description = @description,
            CM_External_Links = @externalLinks,
            CM_EPR_List = @eprList,
            CM_EUS_Proposal_List = @eusProposalList,
            CM_Organisms = @organisms,
            CM_Experiment_Prefixes = @experimentPrefixes,
            CM_Data_Release_Restriction = @dataReleaseRestrictionID,
            CM_Fraction_EMSL_Funded = @fractionEMSLFundedToStore,
            CM_EUS_Usage_Type = @eusUsageTypeID
        WHERE Campaign_Num = @campaignName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 14, @campaignName)

        ---------------------------------------------------
        -- Update research team membership
        ---------------------------------------------------
        --
        EXEC @myError = update_research_team_for_campaign
                            @campaignName,
                            @progmgrUsername ,
                            @piUsername,
                            @technicalLead,
                            @samplePreparationStaff,
                            @datasetAcquisitionStaff,
                            @informaticsStaff,
                            @collaborators,
                            @researchTeamID output,
                            @msg output
        --
        If @myError <> 0
        Begin
            Set @message = @msg
            RAISERROR (@message, 11, 1)
        End

        commit transaction @transName

        Set @percentEMSLFunded = CONVERT(int, @fractionEMSLFundedToStore * 100)

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec alter_event_log_entry_user 9, @campaignID, @percentEMSLFunded, @callingUser
            Exec alter_event_log_entry_user 10, @campaignID, @dataReleaseRestrictionID, @callingUser
        End
    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;


        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Campaign ' + @campaignName
            exec post_log_entry 'Error', @logMessage, 'add_update_campaign'
        End

    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_campaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_campaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_campaign] TO [Limited_Table_Write] AS [dbo]
GO
