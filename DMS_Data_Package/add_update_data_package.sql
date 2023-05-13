/****** Object:  StoredProcedure [dbo].[add_update_data_package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_data_package]
/****************************************************
**
**  Desc: Adds new or edits existing item in T_Data_Package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/21/2009 grk
**          05/29/2009 mem - Updated to support Package_File_Folder not allowing null values
**          06/04/2009 grk - Added parameter @creationParams
**                         - Updated to call make_data_package_storage_folder
**          06/05/2009 grk - Added parameter @prismWikiLink, which is used to populate the Wiki_Page_Link field
**          06/08/2009 mem - Now validating @team and @packageType
**          06/09/2009 mem - Now warning user if the team name is changed
**          06/11/2009 mem - Now warning user if the data package name already exists
**          06/11/2009 grk - Added Requester field
**          07/01/2009 mem - Expanced @massTagDatabase to varchar(1024)
**          10/23/2009 mem - Expanded @prismWikiLink to varchar(1024)
**          03/17/2011 mem - Removed extra, unused parameter from make_data_package_storage_folder
**                         - Now only calling make_data_package_storage_folder when @mode = 'add'
**          08/31/2015 mem - Now replacing the symbol & with 'and' in the name when @mode = 'add'
**          02/19/2016 mem - Now replacing a semicolon with a comma when @mode = 'add'
**          10/18/2016 mem - Call update_data_package_eus_info
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          06/19/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**                         - Validate @state
**          11/19/2020 mem - Add @dataDOI and @manuscriptDOI
**          07/05/2022 mem - Include the data package ID when logging errors
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/10/2023 mem - Reword warning messages
**
*****************************************************/
(
    @id int output,                      -- Data Package ID
    @name varchar(128),
    @packageType varchar(128),
    @description varchar(2048),
    @comment varchar(1024),
    @owner varchar(128),
    @requester varchar(128),
    @state varchar(32),
    @team varchar(64),
    @massTagDatabase varchar(1024),
    @dataDOI varchar(255),
    @manuscriptDOI varchar(255),
    @prismWikiLink varchar(1024) output,
    @creationParams varchar(4096) output,
    @mode varchar(12) = 'add',          -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @currentID int
    Declare @currentTeam varchar(64)
    Declare @teamChangeWarning varchar(256)
    Declare @pkgFileFolder varchar(256)

    Set @teamChangeWarning = ''
    Set @message = ''

    Declare @logErrors tinyint = 0

    BEGIN TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_data_package', @raiseError = 1
    If @authorized = 0
    Begin
        RAISERROR ('Access denied', 11, 3)
    End

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @team = IsNull(@team, '')
    Set @packageType = IsNull(@packageType, '')
    Set @description = IsNull(@description, '')
    Set @comment = IsNull(@comment, '')

    If @team = ''
    Begin
        Set @message = 'Data package team cannot be blank'
        RAISERROR (@message, 10, 1)
        Return 51005
    End

    If @packageType = ''
    Begin
        Set @message = 'Data package type cannot be blank'
        RAISERROR (@message, 10, 1)
        Return 51006
    End

    -- Make sure the team name is valid
    If Not Exists (SELECT * FROM T_Data_Package_Teams WHERE Team_Name = @team)
    Begin
        Set @message = 'Invalid data package team: ' + @team
        RAISERROR (@message, 10, 1)
        Return 51007
    End

    -- Make sure the data package type is valid
    If Not Exists (SELECT * FROM T_Data_Package_Type WHERE Name = @packageType)
    Begin
        Set @message = 'Invalid data package type: ' + @packageType
        RAISERROR (@message, 10, 1)
        Return 51008
    End

    ---------------------------------------------------
    -- Get active path
    ---------------------------------------------------
    --
    Declare @rootPath int
    --
    SELECT @rootPath = ID
    FROM T_Data_Package_Storage
    WHERE State = 'Active'

    ---------------------------------------------------
    -- Validate the state
    ---------------------------------------------------

    If Not Exists (SELECT * FROM T_Data_Package_State WHERE [Name] = @state)
    Begin
        Set @message = 'Invalid state: ' + @state
        RAISERROR (@message, 10, 32)
        Return 51009
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- cannot update a non-existent entry
        --
        Set @currentID = 0
        --
        SELECT @currentID = ID,
               @currentTeam = Path_Team
        FROM T_Data_Package
        WHERE (ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @currentID = 0
        Begin
            Set @message = 'Data package ID ' + Cast(@id as varchar(12)) + ' does not exist; cannot update'
            RAISERROR (@message, 10, 1)
            Return 51011
        End

        -- Warn if the user is changing the team
        If IsNull(@currentTeam, '') <> '' And @currentTeam <> @team
        Begin
            Set @teamChangeWarning = 'Warning: Team changed from "' + @currentTeam + '" to "' + @team + '"; the data package files will need to be moved from the old location to the new one'
        End

    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin

        If @name Like '%&%'
        Begin
            -- Replace & with 'and'

            If @name Like '%[a-z0-9]&[a-z0-9]%'
            Begin
                If @name Like '% %'
                    Set @name = Replace(@name, '&', ' and ')
                Else
                    Set @name = Replace(@name, '&', '_and_')
            End
            Else
            Begin
                Set @name = Replace(@name, '&', 'and')
            End
        End

        If @name Like '%;%'
        Begin
            -- Replace each semicolon with a comma
            Set @name = Replace(@name, ';', ',')
        End

        -- Make sure the data package name doesn't already exist
        If Exists (SELECT * FROM T_Data_Package WHERE Name = @name)
        Begin
            Set @message = 'Data package "' + @name + '" already exists; cannot create an identically named data package'
            RAISERROR (@message, 10, 1)
            Return 51011
        End

        INSERT INTO T_Data_Package (
            Name,
            Package_Type,
            Description,
            Comment,
            Owner,
            Requester,
            Created,
            State,
            Package_File_Folder,
            Path_Root,
            Path_Team,
            Mass_Tag_Database,
            Wiki_Page_Link,
            Data_DOI,
            Manuscript_DOI
        ) VALUES (
            @name,
            @packageType,
            @description,
            @comment,
            @owner,
            @requester,
            getdate(),
            @state,
            Convert(varchar(64), NewID()),        -- Package_File_Folder cannot be null and must be unique; this guarantees both.  Also, we'll rename it below using dbo.make_package_folder_name
            @rootPath,
            @team,
            @massTagDatabase,
            IsNull(@prismWikiLink, ''),
            @dataDOI,
            @manuscriptDOI
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            Return 51011
        End

        -- Return ID of newly created entry
        --
        Set @id = IDENT_CURRENT('T_Data_Package')

        ---------------------------------------------------
        -- data package folder and wiki page auto naming
        ---------------------------------------------------
        --
        Set @pkgFileFolder = dbo.make_package_folder_name(@id, @name)
        Set @prismWikiLink = dbo.make_prismwiki_page_link(@id, @name)
        --
        UPDATE T_Data_Package
        SET
            Package_File_Folder = @pkgFileFolder,
            Wiki_Page_Link = @prismWikiLink
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Updating package folder name failed'
            RAISERROR (@message, 10, 1)
            Return 51012
        End

    End

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_Data_Package
        SET
            Name = @name,
            Package_Type = @packageType,
            Description = @description,
            Comment = @comment,
            Owner = @owner,
            Requester = @requester,
            Last_Modified = getdate(),
            State = @state,
            Path_Team = @team,
            Mass_Tag_Database = @massTagDatabase,
            Wiki_Page_Link = @prismWikiLink,
            Data_DOI = @dataDOI,
            Manuscript_DOI = @manuscriptDOI
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed for ID "' + Convert(varchar(12), @id) + '"'
            RAISERROR (@message, 10, 1)
            Return 51013
        End

    End

    ---------------------------------------------------
    -- Create the data package folder when adding a new data package
    ---------------------------------------------------

    If @mode = 'add'
    Begin
        exec @myError = make_data_package_storage_folder @id, @mode, @message=@message output, @callingUser=@callingUser
    End

    If @teamChangeWarning <> ''
    Begin
        If IsNull(@message, '') <> ''
            Set @message = @message + '; ' + @teamChangeWarning
        Else
            Set @message = @teamChangeWarning
    End

    ---------------------------------------------------
    -- Update EUS_Person_ID and EUS_Proposal_ID
    ---------------------------------------------------
    --
    Exec update_data_package_eus_info @id

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output
        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            If Not @ID Is Null
            Begin
                Set @msgForLog = @msgForLog + '; Data Package ID ' + Cast(@ID As Varchar(12))
            End

            Exec post_log_entry 'Error', @msgForLog, 'add_update_data_package'
        End

    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_data_package] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_data_package] TO [DMS_SP_User] AS [dbo]
GO
