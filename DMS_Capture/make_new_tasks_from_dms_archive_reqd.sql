/****** Object:  StoredProcedure [dbo].[make_new_tasks_from_dms_archive_reqd] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_tasks_from_dms_archive_reqd]
/****************************************************
**
**  Desc:
**      Create new jobs from DMS datasets
**      that are in archive required state
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   12/17/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/03/2023 bcg - Update column names for V_DMS_Dataset_Archive_Status
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512) output,
    @importWindowDays INT = 10,
    @loggingEnabled TINYINT = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- temp table to hold candidate jobs
    ---------------------------------------------------

    CREATE TABLE #AUJobs(
        Dataset varchar(128),
        Dataset_ID int
        )

    ---------------------------------------------------
    -- get datasets from DMS that are in archive required state
    ---------------------------------------------------

    INSERT INTO #AUJobs( Dataset,
                         Dataset_ID )
    SELECT Dataset,
           Dataset_ID
    FROM V_DMS_Dataset_Archive_Status
    WHERE Archive_State_ID = 1 AND
          Dataset_State_ID = 3 AND
          Archive_State_Last_Affected > DateAdd(day, -@ImportWindowDays, GetDate())
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting candidate DatasetArchive steps'
        goto Done
    end

    ---------------------------------------------------
    -- make jobs
    ---------------------------------------------------
    --
    IF @infoOnly = 0
    BEGIN
        INSERT INTO T_Tasks (Script, Dataset, Dataset_ID, Comment)
        SELECT DISTINCT
          'DatasetArchive' AS Script,
          Dataset,
          Dataset_ID,
          'Created from direct DMS import' AS Comment
        FROM
          #AUJobs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to add new DatasetArchive steps'
            goto Done
        end
    END


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    If @LoggingEnabled = 1 AND @myError > 0 AND @message <> ''
    Begin
        exec post_log_entry 'Error', @message, 'make_new_tasks_from_dms_archive_reqd'
    End

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_tasks_from_dms_archive_reqd] TO [DDL_Viewer] AS [dbo]
GO
