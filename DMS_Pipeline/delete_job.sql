/****** Object:  StoredProcedure [dbo].[delete_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_job]
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Jobs and T_Job_Steps
**      This procedure was previously called by DeleteAnalysisJob in DMS5
**      However, now DeleteAnalysisJob calls delete_job_if_new_or_failed in this database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          12/31/2008 mem - initial release
**          05/26/2009 mem - Now deleting from T_Job_Step_Dependencies and T_Job_Parameters
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobNum varchar(32),
    @callingUser varchar(128) = '',
    @message varchar(512)='' output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    declare @jobID int = convert(int, @jobNum)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_job', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    declare @transName varchar(32) = 'DeleteBrokerJob'
    begin transaction @transName

    ---------------------------------------------------
    -- delete job dependencies
    ---------------------------------------------------
    --
    DELETE FROM T_Job_Step_Dependencies
    WHERE (Job = @jobID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        set @message = 'Error deleting T_Job_Step_Dependencies'
        goto Done
    end

    ---------------------------------------------------
    -- delete job parameters
    ---------------------------------------------------
    --
    DELETE FROM T_Job_Parameters
    WHERE Job = @jobID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        set @message = 'Error deleting T_Job_Parameters'
        goto Done
    end


    ---------------------------------------------------
    -- delete job steps
    ---------------------------------------------------
    --
    DELETE FROM T_Job_Steps
    WHERE Job = @jobID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error '
        goto Done
    end

    ---------------------------------------------------
    -- delete jobs
    ---------------------------------------------------
    --
    DELETE FROM T_Jobs
    WHERE Job = @jobID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error '
        goto Done
    end

    commit transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_job] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_job] TO [Limited_Table_Write] AS [dbo]
GO
