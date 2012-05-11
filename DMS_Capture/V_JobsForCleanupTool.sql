/****** Object:  View [dbo].[V_JobsForCleanupTool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_JobsForCleanupTool]
AS
SELECT TJD.Job AS JobID,
       TJD.Dataset_ID AS DatasetID,
       TJD.Comment AS JobComment,
       TDS.DS_comment AS DatasetComment
FROM dbo.T_Jobs AS TJD
     INNER JOIN dbo.S_DMS_T_Dataset AS TDS
       ON TJD.Dataset_ID = TDS.Dataset_ID


GO
