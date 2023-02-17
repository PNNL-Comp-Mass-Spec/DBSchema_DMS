/****** Object:  StoredProcedure [dbo].[add_update_local_job_in_broker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_local_job_in_broker]
/****************************************************
**
**  Desc:
**      Create or edit analysis job directly in broker database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   11/16/2010 grk - Initial release
**          03/15/2011 dac - Modified to allow updating in HOLD mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/08/2016 mem - Include job number in errors raised by RAISERROR
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          08/28/2022 mem - When validating @mode = 'update', use state 3 for complete
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int OUTPUT,
    @scriptName varchar(64),
    @priority int,
    @jobParam varchar(8000),
    @comment varchar(512),
    @resultsFolderName varchar(128) OUTPUT,
    @mode varchar(12) = 'add', -- or 'update' or 'reset'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @DebugMode TINYINT = 0
    Declare @errorMsg varchar(128)

    Declare @reset CHAR(1) = 'N'
    If @mode = 'reset'
    Begin
        SET @mode = 'update'
        SET @reset = 'Y'
    End

    BEGIN TRY
        ---------------------------------------------------
        -- Verify that the user can execute this procedure from the given client host
        ---------------------------------------------------

        Declare @authorized tinyint = 0
        Exec @authorized = verify_sp_authorized 'add_update_local_job_in_broker', @raiseError = 1;
        If @authorized = 0
        Begin;
            THROW 51000, 'Access denied', 1;
        End;

        ---------------------------------------------------
        -- does job exist
        ---------------------------------------------------

        DECLARE
            @id INT = 0,
            @state int = 0
        --
        SELECT
            @id = Job ,
            @state = State
        FROM dbo.T_Jobs
        WHERE Job = @job

        IF @mode = 'update' AND @id = 0
        Begin
            Set @errorMsg = 'Cannot update nonexistent job ' + Cast(@job as varchar(9));
            THROW 51001, @errorMsg, 1;
        End

        IF @mode = 'update' AND NOT @state IN (1, 3, 5, 100) -- new, complete, failed, hold
        Begin
        Set @errorMsg = 'Cannot update job ' + Cast(@job as varchar(9)) +
                        ' in state ' + Cast(@state as varchar(9)) + '; must be 1, 3, 5, or 100';
            THROW 51002, @errorMsg, 1;
        End

        ---------------------------------------------------
        -- verify parameters
        ---------------------------------------------------

        ---------------------------------------------------
        -- update mode
        -- restricted to certain job states and limited to certain fields
        -- force reset of job?
        ---------------------------------------------------

        IF @mode = 'update'
        BEGIN --<update>
            BEGIN TRANSACTION

            -- update job and params
            --
            UPDATE   dbo.T_Jobs
            SET      Priority = @priority ,
                    Comment = @comment ,
                    State = CASE WHEN @reset = 'Y' THEN 20 ELSE State END -- 20=resuming (update_job_state will handle final job state update)
            WHERE    Job = @job

            UPDATE   dbo.T_Job_Parameters
            SET      Parameters = CONVERT(XML, @jobParam)
            WHERE    job = @job
            COMMIT

        END --<update>


        ---------------------------------------------------
        -- add mode
        ---------------------------------------------------

        IF @mode = 'add'
        BEGIN --<add>

            set @message = 'Add mode is not implemented; cannot add job ' +
                           Cast(@job as varchar(9)) + ' with state ' + Cast(@state as varchar(9));
            THROW 51003, @message, 1;

            DECLARE @jobParamXML XML = CONVERT(XML, @jobParam)
/*
            exec make_local_job_in_broker
                    @scriptName,
                    @priority,
                    @jobParamXML,
                    @comment,
                    @DebugMode,
                    @job OUTPUT,
                    @resultsFolderName OUTPUT,
                    @message OUTPUT
*/
        END --<add>

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_local_job_in_broker'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_local_job_in_broker] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_local_job_in_broker] TO [DMS_SP_User] AS [dbo]
GO
