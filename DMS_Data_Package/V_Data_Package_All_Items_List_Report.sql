/****** Object:  View [dbo].[V_Data_Package_All_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_All_Items_List_Report]
AS
SELECT Data_Package_ID AS id, 
       '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Job" id="' + CONVERT(varchar(128), Job) + '"/>' AS sel,
       'Job' AS item_type, CONVERT(varchar(128), Job) AS item, Dataset AS parent_entity, Tool AS info, item_added, package_comment, 1 AS sort_key
FROM dbo.t_data_package_analysis_jobs
UNION
SELECT Data_Package_ID AS id, 
       '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Dataset" id="' + Dataset + '"/>' AS sel,
       'Dataset' AS item_type, Dataset AS item, Experiment AS parent_entity, Instrument AS info, item_added, package_comment, 2 AS sort_key
FROM dbo.t_data_package_datasets
UNION
SELECT Data_Package_ID AS id, 
       '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Experiment" id="' + Experiment + '"/>' AS sel,
       'Experiment' AS item_type, Experiment AS item, '' AS parent_entity, '' AS info, item_added, package_comment, 3 AS sort_key
FROM dbo.t_data_package_experiments
UNION
SELECT Data_Package_ID AS id, 
       '<item pkg="' + CONVERT(varchar(12), Data_Package_ID) + '" type="Biomaterial" id="' + Name + '"/>' AS sel,
       'Biomaterial' AS item_type, Name AS item, Campaign AS parent_entity, Type AS info, item_added, package_comment, 4 AS sort_key
FROM dbo.T_Data_Package_Biomaterial


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_All_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_All_Items_List_Report] TO [DMS_SP_User] AS [dbo]
GO
