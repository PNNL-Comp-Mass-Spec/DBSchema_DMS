/****** Object:  View [dbo].[V_Data_Package_Analysis_Jobs_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Analysis_Jobs_Export]
AS
SELECT DPJ.Data_Pkg_ID,
       DPJ.Job,
       DS.Dataset_Num AS Dataset,
       T.AJT_toolName AS Tool,
       DPJ.Package_Comment,
       DPJ.Item_Added,
       DPJ.Data_Pkg_ID AS Data_Package_ID
FROM T_Data_Package_Analysis_Jobs DPJ
     INNER JOIN S_Analysis_Job AJ
       ON AJ.AJ_jobID = DPJ.Job
     INNER JOIN S_Analysis_Tool T
       ON AJ.AJ_analysisToolID = T.AJT_toolID
     INNER JOIN S_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Analysis_Jobs_Export] TO [DDL_Viewer] AS [dbo]
GO
