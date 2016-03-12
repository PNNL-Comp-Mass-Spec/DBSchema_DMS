/****** Object:  View [dbo].[V_Statistics_Analysis_Jobs_by_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Statistics_Analysis_Jobs_by_Day]
AS
SELECT YEAR(T_Analysis_Job.AJ_start) AS [Year],
       MONTH(T_Analysis_Job.AJ_start) AS [Month],
       DAY(T_Analysis_Job.AJ_start) AS [Day],
       CONVERT(date,  CONVERT(char(5), YEAR(T_Analysis_Job.AJ_start)) + '-' + CONVERT(char(2), MONTH(T_Analysis_Job.AJ_start)) + '-' + CONVERT(char(2), DAY(T_Analysis_Job.AJ_start))) as [Date],
       COUNT(*) AS Jobs_Run
FROM T_Analysis_Job
     INNER JOIN T_Analysis_Tool
       ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
WHERE (NOT (T_Analysis_Job.AJ_start IS NULL)) AND
      (T_Analysis_Tool.AJT_toolName <> 'MSClusterDAT_Gen')
GROUP BY YEAR(T_Analysis_Job.AJ_start), MONTH(T_Analysis_Job.AJ_start), DAY(T_Analysis_Job.AJ_start)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Statistics_Analysis_Jobs_by_Day] TO [PNL\D3M578] AS [dbo]
GO
