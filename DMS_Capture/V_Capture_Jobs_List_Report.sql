/****** Object:  View [dbo].[V_Capture_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Jobs_List_Report
AS
SELECT J.job, J.priority, J.script, JSN.Name AS job_state_b, TX.Num_Steps AS steps, TJSX.Step_Tool + ':' + TSSNX.Name AS active_step, J.dataset,
       J.dataset_id, J.results_folder_name, J.imported, J.start, J.finish, J.storage_server, J.instrument, J.instrument_class,
       J.max_simultaneous_captures, J.comment
FROM dbo.T_Jobs AS J INNER JOIN
                      dbo.T_Job_State_Name AS JSN ON J.State = JSN.ID INNER JOIN
                          (SELECT TJS.Job, COUNT(TJS.Step_Number) AS Num_Steps, MAX(CASE WHEN TJS.State <> 1 THEN TJS.Step_Number ELSE 0 END)
                                                   AS Active_Step, SUM(CASE WHEN TJS.Retry_Count > 0 AND TJS.Retry_Count < TST.Number_Of_Retries THEN 1 ELSE 0 END)
                                                   AS Steps_Retrying
                            FROM dbo.T_Job_Steps AS TJS INNER JOIN
                                                   dbo.T_Step_Tools AS TST ON TJS.Step_Tool = TST.Name INNER JOIN
                                                   dbo.T_Jobs AS J ON TJS.Job = J.Job
                            GROUP BY TJS.Job) AS TX ON TX.Job = J.Job INNER JOIN
                      dbo.T_Job_Steps AS TJSX ON J.Job = TJSX.Job AND TX.Active_Step = TJSX.Step_Number INNER JOIN
                      dbo.T_Job_Step_State_Name AS TSSNX ON TJSX.State = TSSNX.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Jobs_List_Report] TO [DDL_Viewer] AS [dbo]
GO
