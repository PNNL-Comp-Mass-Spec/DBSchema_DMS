/****** Object:  View [dbo].[V_Job_Step_Processing_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Processing_Stats]
AS
SELECT JSPS.Entered,
       JSPS.Job,
       J.Dataset,
       JSPS.Step,
       J.Script,
       JS.Tool,
       JS.Start,
       JS.Finish,
       JSPS.RunTime_Minutes AS RunTime_Minutes_Snapshot,
       JS.RunTime_Minutes AS Current_Runtime_Minutes,
       JSPS.Job_Progress AS Job_Progress_Snapshot,
       JS.Job_Progress AS Current_Progress,
       JSPS.RunTime_Predicted_Hours AS Runtime_Predicted_Hours_Snapshot,
       JS.RunTime_Predicted_Hours AS Current_RunTime_Predicted_Hours,
       JSPS.Processor,
       LP.Machine,
       JSPS.ProgRunner_CoreUsage,
       JSPS.CPU_Load,
       JSPS.Actual_CPU_Load,
       JSN.Name AS Current_StateName,
       JS.State AS Current_State
FROM T_Job_Step_Processing_Stats JSPS
     LEFT OUTER JOIN V_Job_Steps JS
       ON JS.Job = JSPS.Job AND
          JS.Step = JSPS.Step
     INNER JOIN T_Jobs J
       ON J.Job = JS.Job
     INNER JOIN T_Job_Step_State_Name JSN
       ON JS.State = JSN.ID
     LEFT OUTER JOIN T_Local_Processors LP
       ON JSPS.Processor = LP.Processor_Name

GO
