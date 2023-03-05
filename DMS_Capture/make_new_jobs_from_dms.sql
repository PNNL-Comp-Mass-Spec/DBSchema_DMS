/****** Object:  StoredProcedure [dbo].[make_new_jobs_from_dms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_jobs_from_dms]
/****************************************************
**
**  Desc:
**      Add dataset capture jobs for datasets in state New in DMS5
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          02/10/2010 dac - Removed comment stating that jobs were created from test script
**          03/09/2011 grk - Added logic to choose different capture script based on instrument group
**          09/17/2015 mem - Added parameter @infoOnly
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/27/2019 mem - Use get_dataset_capture_priority to determine capture job priority using dataset name and instrument group
**          02/03/2023 bcg - Update column names for V_DMS_Get_New_Datasets
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @bypassDMS tinyint = 0,
    @message varchar(512) = '' output,
    @maxJobsToProcess int = 0,
    @logIntervalThreshold int = 15,        -- If this procedure runs longer than this threshold, then status messages will be posted to the log
    @loggingEnabled tinyint = 0,        -- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @logIntervalThreshold seconds elapse
    @loopingUpdateInterval int = 5,        -- Seconds between detailed logging while looping through the dependencies
    @infoOnly tinyint = 0,                -- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
    @debugMode tinyint = 0                -- 0 for no debugging; 1 to see debug messages
)
AS
    set nocount on

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
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'make_new_jobs_from_dms', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @bypassDMS = IsNull(@bypassDMS, 0)
    Set @debugMode = IsNull(@debugMode, 0)
    Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 0)

    set @message = ''

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
        exec post_log_entry 'Progress', @StatusMessage, 'make_new_jobs_from_dms'
    End

    ---------------------------------------------------
    -- Add new jobs
    ---------------------------------------------------
    --
    IF @bypassDMS = 0
    BEGIN -- <AddJobs>

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @StatusMessage = 'Querying DMS'
            exec post_log_entry 'Progress', @StatusMessage, 'make_new_jobs_from_dms'
        End

        If @infoOnly = 0
        Begin -- <InsertQuery>

            INSERT INTO T_Tasks( Script,
                                [Comment],
                                Dataset,
                                Dataset_ID,
                                Priority)
            SELECT CASE
                       WHEN Src.Instrument_Group = 'IMS' THEN 'IMSDatasetCapture'
                       ELSE 'DatasetCapture'
                   END AS Script,
                   '' AS [Comment],
                   Src.Dataset,
                   Src.Dataset_ID,
                   dbo.get_dataset_capture_priority(Src.Dataset, Src.Instrument_Group)
            FROM V_DMS_Get_New_Datasets Src
                 LEFT OUTER JOIN T_Tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID
            WHERE Target.Dataset_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                set @message = 'Error adding new DatasetCapture tasks'
                goto Done
            end

        End -- </InsertQuery>
        Else
        Begin -- <Preview>

            SELECT CASE
                       WHEN Src.Instrument_Group = 'IMS' THEN 'IMSDatasetCapture'
                       ELSE 'DatasetCapture'
                   END AS Script,
                   '' AS [Comment],
                   Src.Dataset,
                   Src.Dataset_ID,
                   dbo.get_dataset_capture_priority(Src.Dataset, Src.Instrument_Group) As Priority
            FROM V_DMS_Get_New_Datasets Src
                 LEFT OUTER JOIN T_Tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID
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
        exec post_log_entry 'Progress', @StatusMessage, 'make_new_jobs_from_dms'
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_jobs_from_dms] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[make_new_jobs_from_dms] TO [DMS_SP_User] AS [dbo]
GO
