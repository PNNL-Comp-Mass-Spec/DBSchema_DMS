/****** Object:  View [dbo].[V_MyEMSL_Upload_Stats_Monthly] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Upload_Stats_Monthly]
AS
SELECT Year(Entered) AS TheYear, Month(Entered) AS TheMonth,
       COUNT(*) AS Bundles,
       SUM(FileCountNew + FileCountUpdated) AS Files,
       CONVERT(decimal(12, 5), SUM(Bytes / 1024.0 / 1024.0 / 1024.0 / 1024.0)) AS TB
FROM T_MyEMSL_Uploads
WHERE (ErrorCode = 0) AND
      (ISNULL(StatusNum, 0) > 0)
GROUP BY Year(Entered), Month(Entered)



GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Upload_Stats_Monthly] TO [DDL_Viewer] AS [dbo]
GO
