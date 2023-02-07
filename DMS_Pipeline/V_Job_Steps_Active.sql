/****** Object:  View [dbo].[V_Job_Steps_Active] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW [dbo].[V_Job_Steps_Active] 
AS
SELECT Job,
       Step,
       Script,
       Tool,
       State_Name AS Step_State,
       Job_State_Name AS Job_State,
       Dataset,
       Start,
       Finish,
       Runtime_Minutes,
       Processor,
       CONVERT(decimal(9, 1), Last_CPU_Status_Minutes / 60.0) AS Last_CPU_Status_Hours,
       Job_Progress,
       RunTime_Predicted_Hours,
       Priority,
       Settings_File,
       Parameter_File,
       State,
       Row_Number() OVER (ORDER BY Case When State = 4 Then -2 When State = 6 Then -1 Else State End, Job DESC, Step) as Sort_Order
FROM ( SELECT JS.Job,
              JS.Dataset,
              JS.Step,
              JS.Script,
              JS.Tool,
              JS.State,
              CASE WHEN FailedJobQ.Job IS NULL OR JS.State = 6
				THEN JS.State_Name
				ELSE JS.State_Name + ' (Failed in T_Jobs)'
              END AS State_Name,
              AJ.AJ_SettingsFileName AS Settings_File,
              AJ.AJ_ParmFileName AS Parameter_File,
              JS.Start,
              JS.Finish,
              JS.RunTime_Minutes,
              JS.Last_CPU_Status_Minutes,
              JS.Job_Progress,
              JS.RunTime_Predicted_Hours,
              JS.Processor,
              JS.Priority,
              JSN.Name AS Job_State_Name
       FROM V_Job_Steps JS
            INNER JOIN dbo.T_Jobs J 
              ON JS.Job = J.Job
            INNER JOIN dbo.T_Job_State_Name JSN 
              ON J.State = JSN.ID
            LEFT OUTER JOIN (
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
				             (J.Start >= DATEADD(day, -21, GETDATE())) 
				     ) LookupQ
				WHERE RowRank = 1
            ) FailedJobQ ON JS.Job = FailedJobQ.Job AND JS.Step = FailedJobQ.Step
            LEFT OUTER JOIN dbo.T_Local_Processors LP
              ON JS.Processor = LP.Processor_Name
            LEFT OUTER JOIN dbo.S_DMS_T_Analysis_Job AJ
              ON JS.Job = AJ.AJ_jobID
       WHERE (JS.State = 6 AND JS.Start >= DATEADD(day, -21, GETDATE()) ) OR			-- Failed within the last 21 days
             (JS.State IN (1,2) AND J.Imported >= DATEADD(day, -120, GETDATE()) ) OR	-- Enabled/Waiting (and job imported within the last 120 days)
             (JS.State NOT IN (1,3,5,6) ) OR											-- Not Waiting, Skipped, Completed, or Failed
             (JS.Start >= DATEADD(day, -1, GETDATE()) ) OR								-- Job started within the last day
             (NOT FailedJobQ.Job IS Null)												-- Job failed in T_Jobs (within the last 21 days)
   ) DataQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_Active] TO [DDL_Viewer] AS [dbo]
GO
