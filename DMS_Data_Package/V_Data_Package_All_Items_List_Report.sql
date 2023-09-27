/****** Object:  View [dbo].[V_Data_Package_All_Items_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_All_Items_List_Report]
AS
SELECT DPJ.Data_Pkg_ID AS id,
       '<item pkg="' + CONVERT(varchar(12), Data_Pkg_ID) + '" type="Job" id="' + CONVERT(varchar(128), Job) + '"/>' AS sel,
       'Job' AS item_type, CONVERT(varchar(128), DPJ.Job) AS item, DS.Dataset_Num AS parent_entity, T.AJT_toolName AS info, DPJ.item_added, DPJ.package_comment, 1 AS sort_key
FROM T_Data_Package_Analysis_Jobs DPJ
     INNER JOIN S_Analysis_Job AJ
       ON AJ.AJ_jobID = DPJ.Job
     INNER JOIN S_Analysis_Tool T
       ON AJ.AJ_analysisToolID = T.AJT_toolID
     INNER JOIN S_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
UNION
SELECT TD.Data_Pkg_ID AS id,
       '<item pkg="' + CONVERT(varchar(12), Data_Pkg_ID) + '" type="Dataset" id="' + DS.Dataset_Num + '"/>' AS sel,
       'Dataset' AS item_type, DS.Dataset_Num AS item, E.Experiment_Num AS parent_entity, InstName.IN_Name AS info, TD.item_added, TD.package_comment, 2 AS sort_key
FROM T_Data_Package_Datasets TD
     INNER JOIN S_Dataset DS
       ON TD.Dataset_ID = DS.Dataset_ID
     INNER JOIN S_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN S_Experiment_List E
       ON DS.Exp_ID = E.Exp_ID
UNION
SELECT DPE.Data_Pkg_ID AS id,
       '<item pkg="' + CONVERT(varchar(12), Data_Pkg_ID) + '" type="Experiment" id="' + E.Experiment_Num + '"/>' AS sel,
       'Experiment' AS item_type, E.Experiment_Num AS item, '' AS parent_entity, '' AS info, DPE.item_added, DPE.package_comment, 3 AS sort_key
FROM T_Data_Package_Experiments DPE
     INNER JOIN S_Experiment_List E
       ON DPE.Experiment_ID = E.Exp_ID
UNION
SELECT DPB.Data_Pkg_ID AS id,
       '<item pkg="' + CONVERT(varchar(12), Data_Pkg_ID) + '" type="Biomaterial" id="' + BioList.CC_Name + '"/>' AS sel,
       'Biomaterial' AS item_type, BioList.CC_Name AS item, C.Campaign_Num AS parent_entity, BLR.[Type] AS info, item_added, package_comment, 4 AS sort_key
FROM T_Data_Package_Biomaterial DPB
     INNER JOIN S_Biomaterial_List BioList
       ON DPB.Biomaterial_ID = BioList.CC_ID
     INNER JOIN S_Campaign_List C
       ON BioList.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN S_V_Biomaterial_List_Report_2 BLR
       ON DPB.Biomaterial_ID = BLR.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_All_Items_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_All_Items_List_Report] TO [DMS_SP_User] AS [dbo]
GO
