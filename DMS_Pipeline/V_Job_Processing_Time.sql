/****** Object:  View [dbo].[V_Job_Processing_Time] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Processing_Time]
AS
SELECT Job,
       SUM(SecondsElapsedMax) / 60.0 AS ProcessingTimeMinutes
FROM ( SELECT Job,
              Step_Tool,
              MAX(ISNULL(SecondsElapsed1, 0) + ISNULL(SecondsElapsed2, 0)) AS SecondsElapsedMax
       FROM ( SELECT Job,
                     Step_Tool,
                     DATEDIFF(SECOND, Start, Finish) AS SecondsElapsed1,
                     CASE
                         WHEN (NOT Start IS NULL) AND
                              Finish IS NULL THEN DATEDIFF(SECOND, Start, getdate())
                         ELSE NULL
                     END AS SecondsElapsed2
              FROM dbo.T_Job_Steps ) AS StatsQ
       GROUP BY Job, Step_Tool ) AS StepToolQ
GROUP BY Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Processing_Time] TO [DDL_Viewer] AS [dbo]
GO
