/****** Object:  StoredProcedure [dbo].[AddUpdateCellCulture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateCellCulture]
/****************************************************
**
**  Desc:
**      Adds new or updates existing cell culture in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/12/2002
**          01/12/2007 grk - Added verification mode
**          03/11/2008 grk - Added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter @callingUser
**          03/25/2008 mem - Now calling AlterEventLogEntryUser if @callingUser is not blank (Ticket #644)
**          05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @ownerPRN and @piPRN contain a person's real name rather than their username
**          08/19/2010 grk - Try-catch for error handling
**          11/15/2012 mem - Renamed parameter @ownerPRN to @contactPRN; renamed column CC_Owner_PRN to CC_Contact_PRN
**                         - Added new fields to support peptide standards
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Fix spelling in error messages
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          11/23/2016 mem - Include the cell culture name when calling PostLogEntry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/02/2016 mem - Add @organismList
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/06/2017 mem - When adding a new entry, only call UpdateOrganismListForBiomaterial if @organismList is not null
**                         - When updating an existing entry, update @organismList to be '' if null (since the DMS website sends null when a form field is blank)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/27/2017 mem - Fix variable name bug
**          11/28/2017 mem - Deprecate old fields that are now tracked by Reference Compounds
**          08/31/2018 mem - Add @mutation, @plasmid, and @cellLine
**                         - Remove deprecated parameters that are now tracked in T_Reference_Compound
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**
*****************************************************/
(
    @cellCultureName varchar(64),       -- Name of biomaterial (or peptide sequence if tracking an MRM peptide)
    @sourceName varchar(64),            -- Source that the material came from; can be a person (onsite or offsite) or a company
    @contactPRN varchar(64),            -- Contact for the Source; typically PNNL staff, but can be offsite person
    @piPRN varchar(32),                 -- Project lead
    @cultureType varchar(32),
    @reason varchar(500),
    @comment varchar(500),
    @campaignNum varchar(64),
    @mode varchar(12) = 'add',          -- 'add', 'update', 'check_add', 'check_update'
    @message varchar(512) output,
    @container varchar(128) = 'na',
    @organismList varchar(max),         -- List of one or more organisms to associate with this biomaterial; stored in T_Biomaterial_Organisms; if null, T_Biomaterial_Organisms is unchanged
    @mutation varchar(64) = '',
    @plasmid varchar(64) = '',
    @cellLine varchar(64) = '',
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateCellCulture', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @cellCultureName = LTrim(RTrim(IsNull(@cellCultureName, '')))
    Set @sourceName = LTrim(RTrim(IsNull(@sourceName, '')))
    Set @contactPRN = LTrim(RTrim(IsNull(@contactPRN, '')))
    Set @piPRN = LTrim(RTrim(IsNull(@piPRN, '')))
    Set @cultureType = LTrim(RTrim(IsNull(@cultureType, '')))
    Set @reason = LTrim(RTrim(IsNull(@reason, '')))
    Set @campaignNum = LTrim(RTrim(IsNull(@campaignNum, '')))

    Set @container = LTrim(RTrim(IsNull(@container, '')))

    -- Note: leave @organismList null
    -- Procedure UpdateOrganismListForBiomaterial will leave T_Biomaterial_Organisms unchanged if @organismList is null

    Set @mutation = LTrim(RTrim(IsNull(@mutation, '')))
    Set @plasmid = LTrim(RTrim(IsNull(@plasmid, '')))
    Set @cellLine = LTrim(RTrim(IsNull(@cellLine, '')))
    Set @callingUser = IsNull(@callingUser, '')

    Set @myError = 0
    If LEN(@campaignNum) < 1
    Begin
        RAISERROR ('Campaign Name must be defined', 11, 1)
    End
    If LEN(@contactPRN) < 1
    Begin
        RAISERROR ('Contact Name must be defined', 11, 3)
    End
    --
    If LEN(@piPRN) < 1
    Begin
        RAISERROR ('Principle Investigator PRN must be defined', 11, 3)
    End
    --
    If LEN(@cellCultureName) < 1
    Begin
        RAISERROR ('Biomaterial Name must be defined', 11, 4)
    End
    --
    If LEN(@sourceName) < 1
    Begin
        RAISERROR ('Source Name must be defined', 11, 5)
    End
    --
    If LEN(@cultureType) < 1
    Begin
        Set @myError = 51001
        RAISERROR ('Culture Type must be defined', 11, 6)
    End
    --
    If LEN(@reason) < 1
    Begin
        RAISERROR ('Reason must be defined', 11, 7)
    End
    --
    If LEN(@campaignNum) < 1
    Begin
        RAISERROR ('Campaign Name must be defined', 11, 8)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @cellCultureID int = 0
    Declare @curContainerID int = 0
    --
    SELECT
        @cellCultureID = CC_ID,
        @curContainerID = CC_Container_ID
    FROM T_Cell_Culture
    WHERE CC_Name = @cellCultureName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error trying to resolve biomaterial ID (cell culture ID)'
        RAISERROR (@msg, 11, 10)
    End

    -- cannot create an entry that already exists
    --
    If @cellCultureID <> 0 and (@mode = 'add' or @mode = 'check_add')
    Begin
        Set @msg = 'Cannot add: Biomaterial "' + @cellCultureName + '" already in database '
        RAISERROR (@msg, 11, 11)
    End

    -- Cannot update a non-existent entry
    --
    If @cellCultureID = 0 and (@mode = 'update' or @mode = 'check_update')
    Begin
        Set @msg = 'Cannot update: Biomaterial "' + @cellCultureName + '" is not in database '
        RAISERROR (@msg, 11, 12)
    End

    ---------------------------------------------------
    -- Resolve campaign number to ID
    ---------------------------------------------------

    Declare @campaignID int = 0
    --
    execute @campaignID = GetCampaignID @campaignNum
    --
    If @campaignID = 0
    Begin
        Set @msg = 'Could not resolve campaign name "' + @campaignNum + '" to ID"'
        RAISERROR (@msg, 11, 13)
    End

    ---------------------------------------------------
    -- Resolve type name to ID
    ---------------------------------------------------

    Declare @typeID int = 0
    --
    SELECT @typeID = ID
    FROM T_Cell_Culture_Type_Name
    WHERE [Name] = @cultureType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Could not resolve type name "' + @cultureType + '" to ID'
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Resolve container name to ID
    ---------------------------------------------------

    Declare @contID int = 0
    --
    If @container = ''
    Begin
        Set @container = 'na'
    End

    SELECT @contID = ID
    FROM T_Material_Containers
    WHERE Tag = @container
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Could not resolve container name "' + @container + '" to ID'
        RAISERROR (@msg, 11, 15)
    End

    ---------------------------------------------------
    -- Resolve current container id to name
    ---------------------------------------------------

    Declare @curContainerName varchar(125) = ''
    --
    SELECT @curContainerName = Tag
    FROM T_Material_Containers
    WHERE ID = @curContainerID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error resolving name of current container'
        RAISERROR (@msg, 11, 16)
    End

    ---------------------------------------------------
    -- Resolve PRNs to user number
    ---------------------------------------------------

    -- Verify that Owner PRN  is valid
    -- and get its id number
    --
    Declare @userID int

    Declare @MatchCount int
    Declare @NewPRN varchar(64)

    execute @userID = GetUserID @contactPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @contactPRN contains simply the username
        --
        SELECT @contactPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @contactPRN
        -- Try to auto-resolve the name

        exec AutoResolveNameToPRN @contactPRN, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match found; update @contactPRN
            Set @contactPRN = @NewPRN
        End

    End

    -- Verify that principle investigator PRN is valid
    -- and get its id number
    --
    execute @userID = GetUserID @piPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @piPRN contains simply the username
        --
        SELECT @piPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        ---------------------------------------------------
        -- @piPRN did not resolve to a User_ID
        -- In case a name was entered (instead of a PRN),
        --  try to auto-resolve using the U_Name column in T_Users
        ---------------------------------------------------

        exec AutoResolveNameToPRN @piPRN, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match was found; update @piPRN
            Set @piPRN = @NewPRN
        End
        Else
        Begin
            Set @msg = 'Could not find entry in database for principle investigator PRN "' + @piPRN + '"'
            RAISERROR (@msg, 11, 17)
        End
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @Mode = 'add'
    Begin -- <add>
        INSERT INTO T_Cell_Culture (
            CC_Name,
            CC_Source_Name,
            CC_Contact_PRN,
            CC_PI_PRN,
            CC_Type,
            CC_Reason,
            CC_Comment,
            CC_Campaign_ID,
            CC_Container_ID,
            Mutation,
            Plasmid,
            Cell_Line,
            CC_Created
        ) VALUES (
            @cellCultureName,
            @sourceName,
            @contactPRN,
            @piPRN,
            @typeID,
            @reason,
            @comment,
            @campaignID,
            @contID,
            @mutation,
            @plasmid ,
            @cellLine,
            GETDATE()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Insert operation failed: "' + @cellCultureName + '"'
            RAISERROR (@msg, 11, 18)
        End

        Set @cellCultureID = SCOPE_IDENTITY()

        -- As a precaution, query T_Cell_Culture using Biomaterial name to make sure we have the correct CC_ID
        Declare @IDConfirm int = 0

        SELECT @IDConfirm = CC_ID
        FROM T_Cell_Culture
        WHERE CC_Name = @cellCultureName

        If @cellCultureID <> IsNull(@IDConfirm, @cellCultureID)
        Begin
            Declare @DebugMsg varchar(512)
            Set @DebugMsg = 'Warning: Inconsistent identity values when adding biomaterial ' + @cellCultureName + ': Found ID ' +
                            Cast(@IDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                            Cast(@cellCultureID as varchar(12))

            exec postlogentry 'Error', @DebugMsg, 'AddUpdateCellCulture'

            Set @cellCultureID = @IDConfirm
        End

        Declare @StateID int = 1

        -- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
            Exec AlterEventLogEntryUser 2, @cellCultureID, @StateID, @callingUser

        -- Material movement logging
        --
        If @curContainerID != @contID
        Begin
            exec PostMaterialLogEntry
                 'Biomaterial Move',
                 @cellCultureName,
                 'na',
                 @container,
                 @callingUser,
                 'Biomaterial (Cell Culture) added'
        End

        If IsNull(@organismList, '') <> ''
        Begin
            -- Update the associated organism(s)
            exec UpdateOrganismListForBiomaterial @cellCultureName, @organismList, @infoOnly=0, @message = @message output
        End

    End -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin -- <update>
        Set @myError = 0
        --
        UPDATE T_Cell_Culture
        Set
            CC_Source_Name    = @sourceName,
            CC_Contact_PRN    = @contactPRN,
            CC_PI_PRN         = @piPRN,
            CC_Type           = @typeID,
            CC_Reason         = @reason,
            CC_Comment        = @comment,
            CC_Campaign_ID    = @campaignID,
            CC_Container_ID   = @contID,
            Mutation          = @mutation,
            Plasmid           = @plasmid,
            Cell_Line         = @cellLine
        WHERE CC_Name = @cellCultureName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Update operation failed: "' + @cellCultureName + '"'
            RAISERROR (@msg, 11, 19)
        End

        -- Material movement logging
        --
        If @curContainerID != @contID
        Begin
            exec PostMaterialLogEntry
                 'Biomaterial Move',
                 @cellCultureName,
                 @curContainerName,
                 @container,
                 @callingUser,
                 'Biomaterial (Cell Culture) updated'
        End

        -- Update the associated organism(s)
        Set @organismList = IsNull(@organismList, '')
        exec UpdateOrganismListForBiomaterial @cellCultureName, @organismList, @infoOnly=0, @message = @message output

    End -- </update>

    End TRY
    Begin CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Biomaterial ' + @cellCultureName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateCellCulture'
        End

    End CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCellCulture] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCellCulture] TO [Limited_Table_Write] AS [dbo]
GO
