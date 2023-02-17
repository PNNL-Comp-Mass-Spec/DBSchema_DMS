/****** Object:  StoredProcedure [dbo].[set_up_to_extend_existing_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_up_to_extend_existing_job]
/****************************************************
**
**  Desc:
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/03/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- If job not in main tables,
    -- restore it from most recent successful historic job.
    ---------------------------------------------------
    --
    exec @myError = copy_history_to_job @job, @message
    --
    if @myError <> 0
        goto Done

    ---------------------------------------------------
    --
    ---------------------------------------------------
    --
    INSERT INTO #Jobs
    SELECT Job, Priority,  Script,  State,  Dataset,  Dataset_ID, Results_Folder_Name
    FROM T_Jobs
    WHERE Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to get jobs for processing'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_up_to_extend_existing_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[set_up_to_extend_existing_job] TO [Limited_Table_Write] AS [dbo]
GO
