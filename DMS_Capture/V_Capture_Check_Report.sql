/****** Object:  View [dbo].[V_Capture_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Check_Report
AS
SELECT J.job,
       J.script,
       JSN.Name AS state,
       TX.Steps_Retrying AS retry,
       TX.Num_Steps AS steps,
       JSX.Tool + ':' + TSSNX.Name AS active_step,
       J.dataset,
       J.results_folder_name,
       J.storage_server,
       J.priority,
       J.imported,
       J.start,
       J.finish,
       J.instrument,
       J.instrument_class,
       J.max_simultaneous_captures,
       J.comment
FROM dbo.T_Tasks AS J
     INNER JOIN dbo.T_Task_State_Name AS JSN
       ON J.State = JSN.ID
     INNER JOIN ( SELECT JS.Job,
                         COUNT(JS.Step) AS Num_Steps,
                         MAX(CASE
                                 WHEN JS.State <> 1 THEN JS.Step
                                 ELSE 0
                             END) AS Active_Step,
                         SUM(CASE
                                 WHEN JS.Retry_Count > 0
                                      AND
                                      JS.Retry_Count < TST.Number_Of_Retries THEN 1
                                 ELSE 0
                             END) AS Steps_Retrying
                  FROM dbo.T_Task_Steps AS JS
                       INNER JOIN dbo.T_Step_Tools AS TST
                         ON JS.Tool = TST.Name
                       INNER JOIN dbo.T_Tasks AS J
                         ON JS.Job = J.Job
                  WHERE (NOT (J.State IN (3, 101)))
                  GROUP BY JS.Job ) AS TX
       ON TX.Job = J.Job
     INNER JOIN dbo.T_Task_Steps AS JSX
       ON J.Job = JSX.Job AND
          TX.Active_Step = JSX.Step
     INNER JOIN dbo.T_Task_Step_State_Name AS TSSNX
       ON JSX.State = TSSNX.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Check_Report] TO [DDL_Viewer] AS [dbo]
GO
