/****** Object:  View [dbo].[V_Job_Step_Processing_Stats_Daily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Processing_Stats_Daily]
AS
SELECT TheYear AS [Year],
       TheMonth AS [Month],
       TheDay AS [Day],
       CONVERT(date,  CONVERT(char(5), TheYear) + '-' + CONVERT(char(2), TheMonth) + '-' + CONVERT(char(2), TheDay)) as [Date],
       SUM(Job_Steps_Run) AS Job_Steps_Run
FROM (SELECT YEAR(Entered) AS TheYear,
             MONTH(Entered) AS TheMonth,
             DAY(Entered) AS TheDay,
             COUNT(*) AS Job_Steps_Run
      FROM T_Job_Step_Processing_Log
      GROUP BY YEAR(Entered), MONTH(Entered), DAY(Entered)
      UNION
      SELECT YEAR(Entered) AS TheYear,
             MONTH(Entered) AS TheMonth,
             DAY(Entered) AS TheDay,
             COUNT(*) AS Job_Steps_Run
      FROM DMSHistoricLogPipeline.dbo.T_Job_Step_Processing_Log
      GROUP BY YEAR(Entered), MONTH(Entered), DAY(Entered) 
      ) SourceQ
GROUP BY TheYear, TheMonth, TheDay


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Processing_Stats_Daily] TO [PNL\D3M578] AS [dbo]
GO
