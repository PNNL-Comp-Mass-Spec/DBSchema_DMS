/****** Object:  StoredProcedure [dbo].[add_update_attachments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_attachments]
/****************************************************
**
**  Desc: Adds new or edits existing Attachments
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/24/2009
**  Date:   07/22/2010 grk -- allowed update mode
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @attachmentType varchar(24),
    @attachmentName varchar(128),
    @attachmentDescription varchar(1024),
    @ownerUsername varchar(24),
    @active varchar(8),
    @contents text,
    @fileName varchar(128),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0

    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_attachments', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if @mode = 'update'
    begin
        -- cannot update a non-existent entry
        --
        declare @tmp int
        set @tmp = 0
        --
        SELECT @tmp = ID
            FROM  T_Attachments
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = 0
        begin
            set @message = 'No entry could be found in database for update'
            RAISERROR (@message, 10, 1)
            return 51007
        end

    end


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_Attachments (
            Attachment_Type,
            Attachment_Name,
            Attachment_Description,
            Owner_PRN,
            Active,
            Contents,
            File_Name
        ) VALUES (
            @AttachmentType,
            @AttachmentName,
            @AttachmentDescription,
            @ownerUsername,
            @Active,
            @Contents,
            @FileName
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
        set @message = 'Insert operation failed'
        RAISERROR (@message, 10, 1)
        return 51007
        end

        -- return ID of newly created entry
        --
        set @ID = SCOPE_IDENTITY()

    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0
        --

        UPDATE T_Attachments
        SET Attachment_Type = @AttachmentType,
            Attachment_Name = @AttachmentName,
            Attachment_Description = @AttachmentDescription,
            Owner_PRN = @ownerUsername,
            Active = @Active,
            Contents = @Contents,
            File_Name = @FileName
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        end
    end -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_attachments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_attachments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_attachments] TO [Limited_Table_Write] AS [dbo]
GO
