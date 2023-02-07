/****** Object:  View [dbo].[V_Processor_Step_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Step_Stats]
AS
SELECT JS.Processor,
       DATEPART(YEAR, JS.Start) AS The_Year,
       DATEPART(MONTH, JS.Start) AS The_Month,
       COUNT(*) AS Job_Step_Count,
       DateQ.Start_Max
FROM dbo.T_Job_Steps JS
     INNER JOIN ( SELECT Processor,
                         Max(Start) AS Start_Max
                  FROM dbo.T_Job_Steps
                  WHERE (ISNULL(Processor, '') <> '')
                  GROUP BY Processor) AS DateQ
       ON JS.Processor = DateQ.Processor
WHERE (ISNULL(JS.Processor, '') <> '')
GROUP BY JS.Processor, DATEPART(YEAR, JS.Start), DATEPART(MONTH, JS.Start), DateQ.Start_Max

GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Step_Stats] TO [DDL_Viewer] AS [dbo]
GO
