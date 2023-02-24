/****** Object:  StoredProcedure [dbo].[DoAnalysisJobOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DoAnalysisJobOperation]
/****************************************************
**
**  Desc:   Perform analysis job operation defined by 'mode'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/02/2002
**          05/05/2005 grk - removed default mode value
**          02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**          08/19/2010 grk - try-catch for error handling
**          11/18/2010 mem - Now returning 0 after successful call to DeleteNewAnalysisJob
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add @mode previewDelete
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/27/2018 mem - Rename @previewMode to @infoonly
**
*****************************************************/
(
    @jobNum varchar(32),
    @mode varchar(24),          -- 'delete, reset, previewDelete' ; recognizes mode 'reset', but no changes are made (it is a legacy mode)
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(256)

    Declare @jobID int
    Declare @state int

    Declare @result int

    Declare @infoonly tinyint = 0

    If @mode Like 'preview%'
        Set @infoonly = 1

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DoAnalysisJobOperation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Delete job if it is in "new" or "failed" state
    ---------------------------------------------------

    if @mode in ('delete', 'previewDelete')
    begin

        ---------------------------------------------------
        -- delete the job
        ---------------------------------------------------

        execute @result = DeleteNewAnalysisJob @jobNum, @msg output, @callingUser, @infoonly
        --
        if @result <> 0
        begin
            RAISERROR (@msg, 11, 1)
        end

        return 0
    end -- mode 'delete'

    ---------------------------------------------------
    -- Legacy mode; not supported
    ---------------------------------------------------

    if @mode = 'reset'
    begin
        set @msg = 'Warning: the reset mode does not do anything in procedure DoAnalysisJobOperation'
        RAISERROR (@msg, 11, 3)

        return 0
    end -- mode 'reset'

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    set @msg = 'Mode "' + @mode +  '" was unrecognized'
    RAISERROR (@msg, 11, 2)

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'DoAnalysisJobOperation'
    END CATCH
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisJobOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisJobOperation] TO [Limited_Table_Write] AS [dbo]
GO
