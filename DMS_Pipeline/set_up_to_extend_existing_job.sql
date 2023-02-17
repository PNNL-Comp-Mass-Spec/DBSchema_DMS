/****** Object:  StoredProcedure [dbo].[SetUpToExtendExistingJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetUpToExtendExistingJob
/****************************************************
**
**  Desc:
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/03/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**
*****************************************************/
(
    @job int,
    @message varchar(512) output
)
As
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
    exec @myError = CopyHistoryToJob @job, @message
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
GRANT VIEW DEFINITION ON [dbo].[SetUpToExtendExistingJob] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetUpToExtendExistingJob] TO [Limited_Table_Write] AS [dbo]
GO
