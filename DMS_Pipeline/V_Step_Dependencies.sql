/****** Object:  View [dbo].[V_Step_Dependencies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Step_Dependencies]
AS
SELECT JSD.Job,
       JSD.Step,
       JS.Tool,
       JSD.Target_Step AS Target_Step,
       JSD.Condition_Test,
       JSD.Test_Value,
       JSD.Evaluated,
       JSD.Triggered,
       JSD.Enable_Only,
       JS.State
FROM dbo.T_Job_Step_Dependencies JSD
     INNER JOIN dbo.T_Job_Steps JS
       ON JSD.Job = JS.Job AND
          JSD.Step = JS.Step

GO
GRANT VIEW DEFINITION ON [dbo].[V_Step_Dependencies] TO [DDL_Viewer] AS [dbo]
GO
