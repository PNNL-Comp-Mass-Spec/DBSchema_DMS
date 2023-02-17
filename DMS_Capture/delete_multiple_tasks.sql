/****** Object:  StoredProcedure [dbo].[delete_multiple_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_multiple_tasks]
/****************************************************
**
**  Desc:
**      Deletes entries from appropriate tables
**      for all jobs in given list
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/03/2010 grk - Initial release
**          09/11/2012 mem - Renamed from DeleteMultipleJobs to delete_multiple_tasks
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/24/2016 mem - Switch to using parse_delimited_integer_list to parse the list of jobs
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobList varchar(max),
    @callingUser varchar(128) = '',
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_multiple_tasks', @raiseError = 1;
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY

        ---------------------------------------------------
        -- Create and populate a temporary table
        ---------------------------------------------------
        CREATE TABLE #JOBS (
            Job INT
        )
        --
        INSERT INTO #JOBS (Job)
        SELECT Value
        FROM dbo.parse_delimited_integer_list(@jobList, ',')
        ORDER BY Value

        ---------------------------------------------------
        -- Start a transaction
        ---------------------------------------------------
        --
        declare @transName varchar(32)
        set @transName = 'DeleteMultipleJobs'
        begin transaction @transName

        ---------------------------------------------------
        -- Delete job dependencies
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Step_Dependencies
        WHERE (Job IN (SELECT Job FROM #JOBS))

        ---------------------------------------------------
        -- delete job parameters
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Parameters
        WHERE Job IN (SELECT Job FROM #JOBS)

        ---------------------------------------------------
        -- Delete job steps
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Steps
        WHERE Job IN (SELECT Job FROM #JOBS)

        ---------------------------------------------------
        -- Delete jobs
        ---------------------------------------------------
        --
        DELETE FROM T_Jobs
        WHERE Job IN (SELECT Job FROM #JOBS)

        ---------------------------------------------------
        -- Commit the transaction
        ---------------------------------------------------
        --
        commit transaction @transName

    ---------------------------------------------------
    ---------------------------------------------------
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'delete_multiple_tasks'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_multiple_tasks] TO [DDL_Viewer] AS [dbo]
GO
