/****** Object:  StoredProcedure [dbo].[make_new_archive_tasks_from_dms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_archive_tasks_from_dms]
/****************************************************
**
**  Desc:
**      Add dataset archive jobs from DMS
**      for datsets that are in archive 'New' state that aren't already in table
**
**  Auth:   grk
**  Date:   01/08/2010 grk - Initial release
**          10/24/2014 mem - Changed priority to 2 (since we want archive jobs to have priority over non-archive jobs)
**          09/17/2015 mem - Added parameter @infoOnly
**          06/13/2018 mem - Remove unused parameter @debugMode
**          06/27/2019 mem - Changed priority to 3 (since default job priority is now 4)
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @bypassDMS tinyint = 0,
    @message varchar(512) = '' output,
    @maxJobsToProcess int = 0,
    @logIntervalThreshold int = 15,     -- If this procedure runs longer than this threshold, then status messages will be posted to the log
    @loggingEnabled tinyint = 0,        -- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @logIntervalThreshold seconds elapse
    @loopingUpdateInterval int = 5,     -- Seconds between detailed logging while looping through the dependencies
    @infoOnly tinyint = 0               -- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @currJob int
    Declare @Dataset varchar(128)
    Declare @continue tinyint

    Declare @JobsProcessed int
    Declare @JobCountToResume int
    Declare @JobCountToReset int

    Declare @MaxJobsToAddResetOrResume int

    Declare @StartTime datetime
    Declare @LastLogTime datetime
    Declare @StatusMessage varchar(512)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @bypassDMS = IsNull(@bypassDMS, 0)
    Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 0)

    Set @message = ''

    If @maxJobsToProcess <= 0
        Set @MaxJobsToAddResetOrResume = 1000000
    Else
        Set @MaxJobsToAddResetOrResume = @maxJobsToProcess

    Set @StartTime = GetDate()
    Set @loggingEnabled = IsNull(@loggingEnabled, 0)
    Set @logIntervalThreshold = IsNull(@logIntervalThreshold, 15)
    Set @loopingUpdateInterval = IsNull(@loopingUpdateInterval, 5)

    If @logIntervalThreshold = 0
        Set @loggingEnabled = 1

    If @loopingUpdateInterval < 2
        Set @loopingUpdateInterval = 2

    If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
    Begin
        Set @StatusMessage = 'Entering (' + CONVERT(VARCHAR(12), @bypassDMS) + ')'
        exec post_log_entry 'Progress', @StatusMessage, 'make_new_archive_tasks_from_dms'
    End

    ---------------------------------------------------
    --  Add new jobs
    ---------------------------------------------------
    --
    IF @bypassDMS = 0
    BEGIN -- <AddJobs>

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @StatusMessage = 'Querying DMS'
            exec post_log_entry 'Progress', @StatusMessage, 'make_new_archive_tasks_from_dms'
        End

        If @infoOnly = 0
        Begin -- <InsertQuery>

            INSERT INTO T_Tasks (Script,
                                [Comment],
                                Dataset,
                                Dataset_ID,
                                Priority )
            SELECT 'DatasetArchive' AS Script,
                   'Created by import from DMS' AS [Comment],
                   Src.Dataset,
                   Src.Dataset_ID,
                   3 AS Priority
            FROM V_DMS_Get_New_Archive_Datasets Src
                 LEFT OUTER JOIN T_Tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID AND
                      Target.Script = 'DatasetArchive'
            WHERE Target.Dataset_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @message = 'Error creating archive jobs'
                goto Done
            end

        End -- </InsertQuery>
        Else
        Begin -- <Preview>

            SELECT 'DatasetArchive' AS Script,
                   'Created by import from DMS' AS [Comment],
                   Src.Dataset,
                   Src.Dataset_ID,
                   3 AS Priority
            FROM V_DMS_Get_New_Archive_Datasets Src
                 LEFT OUTER JOIN T_Tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID AND
                      Target.Script = 'DatasetArchive'
            WHERE Target.Dataset_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End -- </Preview>

    END -- </AddJobs>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
    Begin
        Set @StatusMessage = 'Exiting'
        exec post_log_entry 'Progress', @StatusMessage, 'make_new_archive_tasks_from_dms'
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_archive_tasks_from_dms] TO [DDL_Viewer] AS [dbo]
GO
