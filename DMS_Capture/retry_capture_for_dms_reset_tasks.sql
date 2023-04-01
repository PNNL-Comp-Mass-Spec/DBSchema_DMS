/****** Object:  StoredProcedure [dbo].[retry_capture_for_dms_reset_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[retry_capture_for_dms_reset_jobs]
/****************************************************
**
**  Desc:   Retry capture for datasets that failed capture
**          but for which the dataset state in DMS is 1=New
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   05/25/2011 mem - Initial version
**          08/16/2017 mem - For jobs with error Error running OpenChrom, only reset the DatasetIntegrity step
**          02/02/2023 bcg - Changed from V_Jobs and V_Job_Steps to V_Tasks and V_Task_Steps
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    CREATE TABLE #SJL (
        Job int NOT NULL,
        ResetFailedStepsOnly tinyint NOT NULL
    )

    ---------------------------------------------------
    -- Look for jobs that are failed and have one or more failed step states
    --  but for which the dataset is present in V_DMS_Get_New_Datasets
    -- These are datasets that have been reset (either via the dataset detail report web page or manually)
    --  and we thus want to retry capture for these datasets
    ---------------------------------------------------
    --
    INSERT INTO #SJL (Job, ResetFailedStepsOnly)
    SELECT DISTINCT J.Job, 0
    FROM V_DMS_Get_New_Datasets NewDS
         INNER JOIN T_Tasks J
           ON NewDS.Dataset_ID = J.Dataset_ID
         INNER JOIN T_Task_Steps JS
           ON J.Job = JS.Job
    WHERE (J.Script IN ('IMSDatasetCapture', 'DatasetCapture')) AND
          (J.State = 5) AND
          (JS.State = 6)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for DatasetCapture jobs to reset'
        goto Done
    end

    If @myRowCount = 0
    Begin
        set @message = 'No datasets were found needing to retry capture'
        goto Done
    End

    -- Construct a comma-separated list of jobs

    Declare @jobList varchar(max)
    Set @jobList = ''

    SELECT @jobList = @jobList + Convert(varchar(12), Job) + ','
    FROM #SJL
    ORDER BY Job

    -- Remove the trailing comma
    If Len(@jobList) > 0
        Set @jobList = SubString(@jobList, 1, Len(@jobList)-1)

    UPDATE #SJL
    SET ResetFailedStepsOnly = 1
    WHERE Job IN ( SELECT Job
                   FROM T_Task_Steps
                   WHERE State = 6 AND
                         Tool = 'DatasetIntegrity' AND
                         Completion_Message = 'Error running OpenChrom' AND
                         Job IN ( SELECT Job FROM #SJL ) )

    If @infoOnly <> 0
    Begin
        SELECT #SJL.ResetFailedStepsOnly, T.*
        FROM V_Tasks T INNER JOIN #SJL ON T.job = #SJL.Job
        ORDER BY T.job

        SELECT #SJL.ResetFailedStepsOnly, TS.*
        FROM V_Task_Steps TS INNER JOIN #SJL ON TS.job = #SJL.Job
        ORDER BY TS.job, TS.step

        Print 'JobList: ' + @jobList
    End
    Else
    Begin -- <a>

        -- Update the job parameters for each job
        exec update_parameters_for_job @jobList, @message output

        -- Reset the job steps using retry_selected_jobs
        -- Fail out any completed steps before performing the reset

        Declare @transName varchar(32) = 'retry_capture_for_dms_reset_jobs'

        begin transaction @transName

        -- First reset job steps for jobs in #SJL with ResetFailedStepsOnly = 1
        --
        UPDATE T_Task_Steps
        SET State = 2
        WHERE State = 6 AND
              Tool = 'DatasetIntegrity' AND
              Completion_Message = 'Error running OpenChrom' AND
              Job IN ( SELECT Job
                       FROM #SJL
                       WHERE ResetFailedStepsOnly = 1 )

        DELETE FROM #SJL
        WHERE ResetFailedStepsOnly = 1

        IF Exists (SELECT * FROM #SJL)
        Begin
            -- Next reset entirely any jobs remaining in #SJL
            UPDATE T_Task_Steps
            SET State = 6
            WHERE State = 5 AND Job IN (SELECT Job FROM #SJL)

            EXEC @myError = retry_selected_jobs @message output
        End
        Else
        Begin
            Set @myError = 0
        End

        IF @myError <> 0
            rollback transaction @transName
        ELSE
            commit transaction @transName

        -- Post a log entry that the job(s) have been reset
        If @JobList LIKE '%,%'
            Set @message = 'Reset dataset capture for jobs ' + @JobList
        Else
            Set @message = 'Reset dataset capture for job ' + @JobList

        exec post_log_entry 'Normal', @message, 'retry_capture_for_dms_reset_jobs'

    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[retry_capture_for_dms_reset_jobs] TO [DDL_Viewer] AS [dbo]
GO
