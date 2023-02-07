/****** Object:  View [dbo].[V_Processor_Step_Tool_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Step_Tool_Stats]
AS
SELECT JS.Processor,
       JS.Step_Tool,
       DATEPART(YEAR, JS.Start) AS The_Year,
       DATEPART(MONTH, JS.Start) AS The_Month,
       COUNT(*) AS Job_Step_Count,
       DateQ.Start_Max
FROM dbo.T_Job_Steps JS
     INNER JOIN ( SELECT Processor,
                         Step_Tool,
                         Max(Start) AS Start_Max
                  FROM dbo.T_Job_Steps
                  WHERE (ISNULL(Processor, '') <> '')
                  GROUP BY Processor, Step_Tool ) AS DateQ
       ON JS.Processor = DateQ.Processor AND
          JS.Step_Tool = DateQ.Step_Tool
WHERE (ISNULL(JS.Processor, '') <> '')
GROUP BY JS.Processor, JS.Step_Tool, DATEPART(YEAR, JS.Start), DATEPART(MONTH, JS.Start), DateQ.Start_Max

GO
