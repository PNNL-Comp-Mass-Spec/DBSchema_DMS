/****** Object:  StoredProcedure [dbo].[AddUpdateFileAttachment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateFileAttachment]
/****************************************************
**
**  Desc:   Adds new or edits existing item in T_File_Attachment
**
**          Note that @entityType will be the same as the
**          DMS website page family name of the item the file attachment
**          is attached to; see the upload method in File_attachment.php
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/30/2011
**          03/30/2011 grk - Don't allow duplicate entries
**          12/16/2011 mem - Convert null descriptions to empty strings
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/11/2021 mem - Store integers in Entity_ID_Value
**          03/27/2022 mem - Assure that Active is 1 when updating an existing file attachment
**
*****************************************************/
(
    @id int,
    @fileName varchar(256),
    @description varchar(1024),
    @entityType varchar(64),            -- Page family name: campaign, experiment, sample_prep_request, lc_cart_configuration, etc.
    @entityID varchar(256),             -- Must be data type varchar since Experiment, Campaign, Cell Culture, and Material Container file attachments are tracked via Experiment Name, Campaign Name, etc.
    @fileSizeBytes varchar(12),         -- This file size is actually in KB
    @archiveFolderPath varchar(256),    -- This path is constructed when File_attachment.php or Experiment_File_attachment.php calls function GetFileAttachmentPath in this database
    @fileMimeType varchar(256),
    @mode varchar(12) = 'add',          -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateFileAttachment', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------
    Declare @tmp int

    If @mode = 'update'
    Begin
        Set @tmp = 0

        SELECT @tmp = ID
        FROM  T_File_Attachment
        WHERE (ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- cannot update a non-existent entry
        If @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 16)
    End

    If @mode = 'add'
    Begin
        -- When a file attachment is deleted the database record is not deleted
        -- Instead, Active is set to 0
        -- If a user re-attaches a "deleted" file to an entity, we need to use 'update' for the @mode
        Set @tmp = 0

        SELECT @tmp = ID
        FROM T_File_Attachment
        WHERE Entity_Type = @entityType AND
              Entity_ID = @entityID AND
              [File_Name] = @fileName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @tmp > 0
        Begin
            Set @mode = 'update'
            Set @id = @tmp
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        INSERT INTO T_File_Attachment (
            [File_Name],
            Description,
            Entity_Type,
            Entity_ID,
            Entity_ID_Value,
            Owner_PRN,
            File_Size_Bytes,
            Archive_Folder_Path,
            File_Mime_Type,
            Active)
        VALUES (
            @fileName,
            IsNull(@description, ''),
            @entityType,
            @entityID,
            Case When @entityType In ('campaign', 'cell_culture', 'experiment', 'material_container')
                 Then Null
                 Else Try_Cast(@entityID As Int)
            End,
            @callingUser,
            @fileSizeBytes,
            @archiveFolderPath,
            @fileMimeType,
            1
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0

        UPDATE T_File_Attachment
        Set Description = IsNull(@description, ''),
            Entity_Type = @entityType,
            Entity_ID = @entityID,
            Entity_ID_Value =
                Case When @entityType In ('campaign', 'cell_culture', 'experiment', 'material_container')
                     Then Null
                     Else Try_Cast(@entityID As Int)
                End,
            File_Size_Bytes = @fileSizeBytes,
            Last_Affected = GETDATE(),
            Archive_Folder_Path = @archiveFolderPath,
            File_Mime_Type = @fileMimeType,
            Active = 1
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @id)

    End -- update mode

    End TRY
    Begin CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddUpdateFileAttachment'
    End CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateFileAttachment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateFileAttachment] TO [DMS2_SP_User] AS [dbo]
GO
