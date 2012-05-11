/****** Object:  View [dbo].[V_Processor_StepTool_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_StepTool_Stats]
AS
SELECT JS.Processor,
       JS.Step_Tool,
       DATEPART(YEAR, JS.Start) AS TheYear,
       DATEPART(MONTH, JS.Start) AS TheMonth,
       COUNT(*) AS JobStepCount,
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
GRANT VIEW DEFINITION ON [dbo].[V_Processor_StepTool_Stats] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_StepTool_Stats] TO [PNL\D3M580] AS [dbo]
GO
