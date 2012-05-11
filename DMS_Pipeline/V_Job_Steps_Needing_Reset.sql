/****** Object:  View [dbo].[V_Job_Steps_Needing_Reset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Job_Steps_Needing_Reset
AS
SELECT JS.Job,
       J.Dataset,
       JS.Step_Number AS Step,
       J.Script,
       JS.Step_Tool,
       JS.State,
       JS.Start,
       JS.Finish,
       JS_Target.Step_Number AS Dependent_Step,
       JS_Target.Step_Tool AS Dependent_Step_Tool,
       JS_Target.State AS Dependent_Step_State,
       JS_Target.Start AS Dependent_Step_Start,
       JS_Target.Finish AS Dependent_Step_Finish
FROM T_Job_Steps JS
     INNER JOIN T_Job_Step_Dependencies
       ON JS.Job = T_Job_Step_Dependencies.Job_ID AND
          JS.Step_Number = T_Job_Step_Dependencies.Step_Number
     INNER JOIN T_Job_Steps JS_Target
       ON T_Job_Step_Dependencies.Job_ID = JS_Target.Job 
          AND
          T_Job_Step_Dependencies.Target_Step_Number = JS_Target.Step_Number
     INNER JOIN T_Jobs J ON JS.Job = J.Job
WHERE JS.State >= 2 AND
      JS.State <> 3 AND
      (JS_Target.State IN (2, 4) OR
       JS_Target.Start > JS.Finish)


GO
