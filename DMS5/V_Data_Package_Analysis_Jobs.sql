/****** Object:  View [dbo].[V_Data_Package_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Analysis_Jobs]
AS
SELECT DPJ.Data_Package_ID,
       DPJ.Job,
       DPJ.Dataset,
       J.AJ_datasetID AS Dataset_ID,
       DPJ.Tool,
       DPJ.Package_Comment,
       DPJ.Item_Added,
       MJ.Folder
FROM dbo.T_Analysis_Job J
     INNER JOIN dbo.S_V_Data_Package_Analysis_Jobs_Export DPJ
       ON J.AJ_jobID = DPJ.Job
     INNER JOIN V_Mage_Analysis_Jobs MJ
       ON J.AJ_jobID = MJ.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
