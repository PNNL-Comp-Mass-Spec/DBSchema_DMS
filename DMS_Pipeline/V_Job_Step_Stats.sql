/****** Object:  View [dbo].[V_Job_Step_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Stats]
AS
SELECT J.Dataset,
       J.Script,
       StepToolQ.Job,
       SUM(StepToolQ.JobSteps) AS JobSteps,
       SUM(StepToolQ.SecondsElapsedMax) / 60.0 AS ProcessingTimeMinutes,
       SUM(StepToolQ.SecondsElapsedTotal) / 60.0 AS MachineTimeMinutes,
       J.Start,
       J.Finish,
       J.State AS JobState,
       JSN.Name AS StateName,
       SUM(StepToolQ.StepCount_Pending) AS StepCount_Pending,
       SUM(StepToolQ.StepCount_Running) AS StepCount_Running,
       SUM(StepToolQ.StepCount_Completed) AS StepCount_Completed,
       SUM(StepToolQ.StepCount_Failed) AS StepCount_Failed
FROM ( SELECT Job,
              Step_Tool,
              MAX(ISNULL(SecondsElapsed1, 0) + ISNULL(SecondsElapsed2, 0)) AS SecondsElapsedMax,
              SUM(ISNULL(SecondsElapsed1, 0) + ISNULL(SecondsElapsed2, 0)) AS SecondsElapsedTotal,
              COUNT(*) AS JobSteps,
              SUM(CASE WHEN state IN (3, 5)    THEN 1 ELSE 0 END) AS StepCount_Completed,
              SUM(CASE WHEN state = 4          THEN 1 ELSE 0 END) AS StepCount_Running,
              SUM(CASE WHEN state = 6          THEN 1 ELSE 0 END) AS StepCount_Failed,
              SUM(CASE WHEN state IN (1, 2, 7) THEN 1 ELSE 0 END) AS StepCount_Pending
	   FROM (SELECT Job,
					Step_Tool,
					State,
					DATEDIFF(SECOND, Start, Finish) AS SecondsElapsed1,
					CASE
						WHEN NOT Start IS NULL AND Finish IS NULL 
						THEN DATEDIFF(SECOND, Start, getdate())
						ELSE NULL
					END AS SecondsElapsed2
			 FROM T_Job_Steps JS
			 UNION
			 SELECT Job,
					Step_Tool,
					State,
					DATEDIFF(SECOND, Start, Finish) AS SecondsElapsed1,
					CASE
						WHEN NOT Start IS NULL AND Finish IS NULL 
						THEN DATEDIFF(SECOND, Start, getdate())
						ELSE NULL
					END AS SecondsElapsed2
			 FROM T_Job_Steps_History JSH
			 WHERE NOT Job IN ( SELECT Job
								FROM T_Job_Steps ) 
			) StatsQ
       GROUP BY Job, Step_Tool 
     ) StepToolQ
     INNER JOIN T_Jobs J
       ON StepToolQ.Job = J.Job
     INNER JOIN T_Job_State_Name JSN
       ON JSN.ID = J.State
GROUP BY StepToolQ.Job, J.Script, J.Dataset, J.Start, J.Finish, J.State, JSN.Name



GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Stats] TO [PNL\D3M578] AS [dbo]
GO
