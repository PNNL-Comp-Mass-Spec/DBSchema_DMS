/****** Object:  View [dbo].[V_Data_Package_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Aggregation_List_Report]
AS
SELECT dbo.GetXMLRow(TD.Data_Package_ID, 'Job', TM.Job) AS sel,
       TM.job,
       TM.state,
       TM.tool,
       TD.dataset,
       TD.dataset_id,
       CASE
           WHEN TJ.Job IS NULL THEN 'No'
           ELSE 'Yes'
       END AS in_package,
       TM.param_file,
       TM.settings_file,
       TD.data_package_id,
       TM.organism_db,
       TM.protein_collection_list,
       TM.protein_options,
       DS.rating,
	   DS.instrument
FROM T_Data_Package_Datasets AS TD
     LEFT OUTER JOIN S_V_Dataset_List_Report_2 AS DS
       ON TD.Dataset_ID = DS.ID
     LEFT OUTER JOIN S_V_Analysis_Job_List_Report_2 AS TM
       ON TD.Dataset_ID = TM.Dataset_ID
     LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS TJ
       ON TJ.Job = TM.Job AND
          TJ.Dataset_ID = TD.Dataset_ID AND
          TJ.Data_Package_ID = TD.Data_Package_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Aggregation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
