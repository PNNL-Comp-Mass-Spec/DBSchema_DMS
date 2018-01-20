/****** Object:  View [dbo].[V_Job_Processing_Time] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Processing_Time]
AS
SELECT Job,
       SUM(MaxSecondsElapsedByTool) / 60.0 AS ProcessingTimeMinutes,
       SUM(MaxSecondsElapsedByTool_CompletedSteps) / 60.0 AS ProcTimeMinutes_CompletedSteps
FROM ( SELECT Job,
              Step_Tool,
              MAX(ISNULL(SecondsElapsedComplete, 0) + ISNULL(SecondsElapsedInProgress, 0)) AS MaxSecondsElapsedByTool,
              MAX(ISNULL(SecondsElapsedComplete, 0)) AS MaxSecondsElapsedByTool_CompletedSteps
       FROM ( SELECT Job,
                     Step_Tool,
                     Case WHEN (NOT Start IS NULL) And Finish > Start Then DATEDIFF(SECOND, Start, Finish) Else Null End AS SecondsElapsedComplete,
                     CASE
                         WHEN (NOT Start IS NULL) AND
                              Finish IS NULL THEN DATEDIFF(SECOND, Start, getdate())
                         ELSE NULL
                     END AS SecondsElapsedInProgress
              FROM dbo.T_Job_Steps ) AS StatsQ
       GROUP BY Job, Step_Tool ) AS StepToolQ
GROUP BY Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Processing_Time] TO [DDL_Viewer] AS [dbo]
GO
