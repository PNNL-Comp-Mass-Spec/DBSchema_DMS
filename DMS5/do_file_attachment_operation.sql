/****** Object:  StoredProcedure [dbo].[DoFileAttachmentOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DoFileAttachmentOperation] 
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
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @ID int,
    @mode varchar(12),                  -- Delete
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'DoFileAttachmentOperation', @raiseError = 1
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
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        Exec PostLogEntry 'Error', @message, 'DoFileAttachmentOperation'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoFileAttachmentOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoFileAttachmentOperation] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoFileAttachmentOperation] TO [DMS2_SP_User] AS [dbo]
GO
