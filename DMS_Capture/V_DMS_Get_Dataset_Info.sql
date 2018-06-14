/****** Object:  View [dbo].[V_DMS_Get_Dataset_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Get_Dataset_Info]
AS
SELECT Dataset_Num, DS_created, IN_name, DSS_name, DS_comment, DS_folder_name, SP_path, SP_vol_name_server, SP_vol_name_client, DST_name, 
       DS_sec_sep, DS_Well_num, DS_Oper_PRN, Dataset_ID, Experiment_Num, EX_Reason, EX_organism_name, EX_cell_culture_list, 
       EX_researcher_PRN, EX_comment, EX_lab_notebook_ref, Campaign_Num, CM_Project_Num, CM_Comment, CM_created, 
       EX_sample_concentration, EX_Labelling, Reporter_Mz_Min, Reporter_Mz_Max
FROM S_DMS_V_DatasetFullDetails


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Get_Dataset_Info] TO [DDL_Viewer] AS [dbo]
GO
