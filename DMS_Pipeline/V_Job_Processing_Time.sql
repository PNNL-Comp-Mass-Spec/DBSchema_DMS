/****** Object:  View [dbo].[V_Job_Processing_Time] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Job_Processing_Time]
AS
SELECT Job,
       SUM(MaxSecondsElapsedByTool) / 60.0 AS Processing_Time_Minutes,
       SUM(MaxSecondsElapsedByTool_CompletedSteps) / 60.0 AS Proc_Time_Minutes_Completed_Steps
FROM ( SELECT Job,
              Tool,
              MAX(ISNULL(SecondsElapsedComplete, 0) + ISNULL(SecondsElapsedInProgress, 0)) AS MaxSecondsElapsedByTool,
              MAX(ISNULL(SecondsElapsedComplete, 0)) AS MaxSecondsElapsedByTool_CompletedSteps
       FROM ( SELECT Job,
                     Tool,
                     CASE WHEN (State = 9 OR Retry_Count > 0) AND NOT Remote_Start IS NULL THEN
                              CASE WHEN (NOT Remote_Start IS NULL) And Remote_Finish > Remote_Start
                              THEN DATEDIFF(second, Remote_Start, Remote_Finish)
                              ELSE NULL END
                          ELSE
                              CASE WHEN (NOT Start IS NULL) And Finish > Start
                              THEN DATEDIFF(second, Start, Finish)
                              ELSE NULL END
		             END As SecondsElapsedComplete,
                     CASE WHEN (State = 9 OR Retry_Count > 0) AND NOT Remote_Start IS NULL THEN
                              CASE WHEN Remote_Finish IS NULL
                              THEN DATEDIFF(second, Remote_Start, GetDate())
                              ELSE NULL END
                          ELSE
                              CASE WHEN (NOT Start IS NULL) AND Finish IS NULL
                              THEN DATEDIFF(second, Start, GetDate())
                              ELSE NULL END
                     END AS SecondsElapsedInProgress
              FROM dbo.T_Job_Steps ) AS StatsQ
       GROUP BY Job, Tool ) AS StepToolQ
GROUP BY Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Processing_Time] TO [DDL_Viewer] AS [dbo]
GO
