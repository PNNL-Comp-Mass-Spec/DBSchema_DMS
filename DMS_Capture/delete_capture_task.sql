/****** Object:  StoredProcedure [dbo].[delete_capture_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_capture_task]
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Tasks and T_Task_Steps
**      This procedure is called by DeleteAnalysisJob in DMS5
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          09/12/2009 mem - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/11/2012 mem - Renamed from DeleteJob to delete_capture_task
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @job varchar(32),
    @callingUser varchar(128) = '',
    @message varchar(512)='' output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    declare @jobID int = convert(int, @job)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_capture_task', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Declare @transName varchar(32) = 'DeleteBrokerJob'

    begin transaction @transName

    ---------------------------------------------------
    -- Delete the job dependencies
    ---------------------------------------------------
    --
    DELETE FROM T_Task_Step_Dependencies
    WHERE Job = @jobID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        set @message = 'Error deleting T_Task_Step_Dependencies'
        goto Done
    end

    ---------------------------------------------------
    -- Delete the job parameters
    ---------------------------------------------------
    --
    DELETE FROM T_Task_Parameters
    WHERE Job = @jobID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        set @message = 'Error deleting T_Task_Parameters'
        goto Done
    end

    ---------------------------------------------------
    -- Delete the job steps
    ---------------------------------------------------
    --
    DELETE FROM T_Task_Steps
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
    -- Delete the job
    ---------------------------------------------------
    --
    DELETE FROM T_Tasks
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
GRANT VIEW DEFINITION ON [dbo].[delete_capture_task] TO [DDL_Viewer] AS [dbo]
GO
