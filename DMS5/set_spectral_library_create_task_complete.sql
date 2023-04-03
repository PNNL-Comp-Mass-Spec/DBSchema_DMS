/****** Object:  StoredProcedure [dbo].[set_spectral_library_create_task_complete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_spectral_library_create_task_complete]
/****************************************************
**
**  Desc:
**      Set a spectral library's state to 3 (complete) or 4 (failed), depending on @completionCode
**
**  Auth:   mem
**  Date:   04/03/2023 mem - Initial Release
**
*****************************************************/
(
    @libraryId int,
    @completionCode int,                    -- 0 means success; non-zero means failure
    @message varchar(255) = '' Output,
    @returnCode varchar(64) = '' Output
)
As
Begin
    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @libraryName varchar(255) = ''
    Declare @libraryStateId int = 0
    Declare @newLibraryState Int

    Set @message = ''
    Set @returnCode  = ''

    BEGIN TRY
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        Set @libraryId = Coalesce(@libraryId, 0)
        Set @completionCode = Coalesce(@completionCode, 0)

        ---------------------------------------------------
        -- Lookup the current state of the library
        ---------------------------------------------------

        SELECT @libraryName = Library_Name,
               @libraryStateId = Library_State_ID
        FROM T_Spectral_Library
        WHERE Library_ID = @libraryId
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Spectral library ID ' + Cast(@libraryId As Varchar(9)) + ' not found in T_Spectral_Library'
            exec post_log_entry 'Error', @message, 'set_spectral_library_create_task_complete'

            Set @returnCode = 'U5201';
            Return 5201;
        End

        If @libraryStateId <> 2
        Begin
            Set @message = 'Spectral library ID ' + Cast(@libraryId As Varchar(9)) + ' has state ' + Cast(@libraryStateId As Varchar(9)) + ' ' +
                           'in T_Spectral_Library instead of state 2 (In Progress); leaving the state unchanged'
            exec post_log_entry 'Error', @message, 'set_spectral_library_create_task_complete'

            Set @returnCode = 'U5202';
            Return 5202;
        End

        If @completionCode = 0
            Set @newLibraryState = 3     -- Complete
        Else
            Set @newLibraryState = 4     -- Failed

        UPDATE T_Spectral_Library
        SET Library_State_ID = @newLibraryState,
            Completion_Code = @completionCode
        WHERE Library_ID = @libraryId And
              Library_State_ID = 2
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            Set @message = 'Error setting the state for Spectral library ID ' + Cast(@libraryId As Varchar(9)) + ' to ' + Cast(@newLibraryState as varchar(9)) + '; no rows were updated'
            exec post_log_entry 'Error', @message, 'set_spectral_library_create_task_complete'

            Set @returnCode = 'U5203';
            Return 5203;
        End

        Return 0;

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @message = 'Error updating the state for spectral library ID ' + Cast(@libraryId As Varchar(9)) + ': ' + @message
        exec post_log_entry 'Error', @message, 'get_spectral_library_id'

        Set @returnCode = 'U5205';
        Return 5205;
    END Catch

END

GO
GRANT VIEW DEFINITION ON [dbo].[set_spectral_library_create_task_complete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_spectral_library_create_task_complete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_spectral_library_create_task_complete] TO [svc-dms] AS [dbo]
GO
