/****** Object:  View [dbo].[V_Data_Package_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Aggregation_List_Report]
AS
SELECT dbo.get_xml_row(TD.Data_Pkg_ID, 'Job', J.Job) AS sel,
       J.job,
       J.state,
       J.tool,
       DS.dataset,
       TD.dataset_id,
       CASE
           WHEN DPJ.Job IS NULL THEN 'No'
           ELSE 'Yes'
       END AS in_package,
       J.param_file,
       J.settings_file,
       TD.Data_Pkg_ID AS data_package_id,
       J.organism_db,
       J.protein_collection_list,
       J.protein_options,
       DS.rating,
	   DS.instrument
FROM T_Data_Package_Datasets AS TD
     INNER JOIN S_V_Dataset_List_Report_2 AS DS
       ON TD.Dataset_ID = DS.ID
     LEFT OUTER JOIN S_V_Analysis_Job_List_Report_2 AS J
       ON TD.Dataset_ID = J.Dataset_ID
     LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS DPJ
       ON DPJ.Job = J.Job AND
          DPJ.Dataset_ID = TD.Dataset_ID AND
          DPJ.Data_Pkg_ID = TD.Data_Pkg_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Aggregation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
