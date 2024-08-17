/****** Object:  StoredProcedure [dbo].[do_file_attachment_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_file_attachment_operation]
/****************************************************
**
**  Desc:
**    Performs operation given by @mode
**    on entity given by @ID
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   09/05/2012
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @id int,
    @mode varchar(12),                  -- Delete
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_file_attachment_operation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Set @message = ''

    BEGIN TRY

        ---------------------------------------------------
        -- "Delete" the attachment
        -- In reality, we change active to 0
        ---------------------------------------------------
        --
        If @mode = 'delete'
        Begin
            UPDATE T_File_Attachment
            SET Active = 0
            WHERE ID = @ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Delete operation failed'
                RAISERROR (@message, 10, 1)
                Return 51007
            End
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'do_file_attachment_operation'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[do_file_attachment_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_file_attachment_operation] TO [DMS2_SP_User] AS [dbo]
GO
