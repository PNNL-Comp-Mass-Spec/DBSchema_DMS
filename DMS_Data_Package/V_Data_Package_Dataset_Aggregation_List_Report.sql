/****** Object:  View [dbo].[V_Data_Package_Dataset_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_Aggregation_List_Report]
AS
SELECT DPJ.Data_Pkg_ID AS ID,
       DS.Dataset_Num AS Dataset,
       COUNT(*) AS Jobs
FROM T_Data_Package_Analysis_Jobs DPJ
     INNER JOIN S_Analysis_Job AJ
       ON AJ.AJ_jobID = DPJ.Job
     INNER JOIN S_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
GROUP BY DS.Dataset_Num, DPJ.Data_Pkg_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Dataset_Aggregation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
