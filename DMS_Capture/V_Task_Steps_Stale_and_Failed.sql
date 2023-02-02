/****** Object:  View [dbo].[V_Task_Steps_Stale_and_Failed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Steps_Stale_and_Failed] 
AS
SELECT warning_message,
       dataset,
       dataset_id,
       job,
       script,
       tool,
       CONVERT(int, runtime_minutes) AS runtime_minutes,
       CONVERT(decimal(9, 1), job_progress) AS job_progress,
       runtime_predicted_hours,
       state_name As state_name,
       CONVERT(decimal(9, 1), last_cpu_status_minutes / 60.0) AS last_cpu_status_hours,
       processor,
       start,
       step,
       completion_message,
       evaluation_message
FROM ( SELECT  CASE WHEN (JS.State = 4 AND DATEDIFF(hour, JS.Start, GetDate()) >= 5 )                               THEN 'Job step running over 5 hours'
                    WHEN (JS.State = 6 AND JS.Start >= DATEADD(day, -14, GETDATE()) AND JS.Job_State <> 101 )       THEN 'Job step failed within the last 14 days'
                    WHEN (NOT FailedJobQ.Job IS Null)                                                               THEN 'Overall job state is "failed"'
                    ELSE ''
                    END AS warning_message,
              JS.job,
              JS.dataset,
              JS.dataset_id,
              JS.step,
              JS.script,
              JS.tool,
              JS.state,
              CASE
                  WHEN JS.State = 4 THEN 'Stale'
                  ELSE CASE WHEN FailedJobQ.Job IS NULL OR JS.State = 6
                       THEN JS.state_name
                       ELSE JS.state_name + ' (Failed in T_Jobs)'
                       END
              END AS state_name,
              JS.start,
              JS.runtime_minutes,
              JS.last_cpu_status_minutes,
              JS.job_progress,
              JS.runtime_predicted_hours,
              JS.processor,
              JS.priority,
              ISNULL(JS.Completion_Message, '') AS completion_message,
              ISNULL(JS.Evaluation_Message, '') AS evaluation_message
       FROM V_Task_Steps JS
            LEFT OUTER JOIN (
                -- Look for jobs that are failed and started within the last 14 days
                -- The subquery is used to find the highest step state for each job
				SELECT Job,
				       Step_Number AS Step
				FROM ( SELECT JS.Job,
				              JS.Step_Number,
				              JS.State AS StepState,
				              Row_Number() OVER ( PARTITION BY J.Job ORDER BY JS.State DESC ) AS RowRank
				       FROM dbo.T_Jobs J
				            INNER JOIN dbo.T_Job_Steps JS
				              ON J.Job = JS.Job
				       WHERE (J.State = 5) AND
				             (J.Start >= DATEADD(day, -14, GETDATE())) 
				     ) LookupQ
				WHERE RowRank = 1
            ) FailedJobQ ON JS.Job = FailedJobQ.Job AND JS.Step = FailedJobQ.Step
            LEFT OUTER JOIN dbo.T_Local_Processors LP
              ON JS.Processor = LP.Processor_Name
   ) DataQ
WHERE Warning_Message <> ''


GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Steps_Stale_and_Failed] TO [DDL_Viewer] AS [dbo]
GO
