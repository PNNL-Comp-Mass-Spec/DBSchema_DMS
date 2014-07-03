/****** Object:  View [dbo].[V_MyEMSL_Upload_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MyEMSL_Upload_Stats]
AS
SELECT CAST(CONVERT(char(11), Entered, 113) AS date) AS Entered,
       COUNT(*) AS Bundles,
       SUM(FileCountNew + FileCountUpdated) AS Files,
       CONVERT(decimal(12, 5), SUM(Bytes / 1024.0 / 1024.0 / 1024.0)) AS GB
FROM T_MyEMSL_Uploads
WHERE (ErrorCode = 0) AND
      (ISNULL(StatusNum, 0) > 0)
GROUP BY CAST(CONVERT(char(11), Entered, 113) AS date)


GO
