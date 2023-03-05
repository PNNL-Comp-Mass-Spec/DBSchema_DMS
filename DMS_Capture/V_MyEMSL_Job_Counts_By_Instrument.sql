/****** Object:  View [dbo].[V_MyEMSL_Job_Counts_By_Instrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MyEMSL_Job_Counts_By_Instrument] AS
SELECT T_Tasks.Instrument,
       CONVERT(decimal(9, 1), SUM(T_MyEMSL_Uploads.Bytes / 1024.0 / 1024.0 / 1024.0)) AS GB,
       COUNT(T_Tasks.Instrument) AS Upload_Count
FROM T_MyEMSL_Uploads
     INNER JOIN T_Tasks
       ON T_MyEMSL_Uploads.Job = T_Tasks.Job
WHERE T_MyEMSL_Uploads.ErrorCode = 0
GROUP BY T_Tasks.Instrument

GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Job_Counts_By_Instrument] TO [DDL_Viewer] AS [dbo]
GO
