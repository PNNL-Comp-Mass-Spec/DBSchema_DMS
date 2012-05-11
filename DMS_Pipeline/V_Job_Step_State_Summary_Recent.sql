/****** Object:  View [dbo].[V_Job_Step_State_Summary_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Job_Step_State_Summary_Recent]
AS
SELECT JS.Step_Tool,
       JS.State,
       JSN.Name AS StateName,
       COUNT(*) AS StepCount,
       MAX(JS.Start) AS Start_Max
FROM dbo.T_Job_Steps JS
     INNER JOIN dbo.T_Job_Step_State_Name JSN
       ON JS.State = JSN.ID
WHERE (JS.Job IN ( SELECT DISTINCT Job
                   FROM T_Job_Step_Events
                   WHERE Entered >= DateAdd(Day, -120, getdate()) ))
GROUP BY JS.Step_Tool, JS.State, JSN.Name



GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_State_Summary_Recent] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_State_Summary_Recent] TO [PNL\D3M580] AS [dbo]
GO
