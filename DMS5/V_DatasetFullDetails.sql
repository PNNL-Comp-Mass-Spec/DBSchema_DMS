/****** Object:  View [dbo].[V_DatasetFullDetails] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DatasetFullDetails
AS
SELECT     dbo.T_Dataset.Dataset_Num, dbo.T_Dataset.DS_created, dbo.T_Instrument_Name.IN_name, dbo.T_DatasetStateName.DSS_name, 
                      ISNULL(dbo.T_Dataset.DS_comment, '') AS DS_comment, dbo.T_Dataset.DS_folder_name, dbo.t_storage_path.SP_path, 
                      dbo.t_storage_path.SP_vol_name_server, dbo.t_storage_path.SP_vol_name_client, dbo.T_DatasetTypeName.DST_name, dbo.T_Dataset.DS_sec_sep, 
                      ISNULL(dbo.T_Dataset.DS_well_num, 'na') AS DS_Well_num, dbo.T_Dataset.DS_Oper_PRN, dbo.T_Dataset.Dataset_ID, 
                      dbo.T_Experiments.Experiment_Num, ISNULL(dbo.T_Experiments.EX_reason, '') AS EX_Reason, dbo.T_Organisms.OG_name AS EX_organism_name, 
                      ISNULL(dbo.T_Experiments.EX_cell_culture_list, '') AS EX_cell_culture_list, dbo.T_Experiments.EX_researcher_PRN, 
                      ISNULL(dbo.T_Experiments.EX_comment, '') AS EX_comment, ISNULL(dbo.T_Experiments.EX_lab_notebook_ref, 'na') AS EX_lab_notebook_ref, 
                      dbo.T_Campaign.Campaign_Num, dbo.T_Campaign.CM_Project_Num, ISNULL(dbo.T_Campaign.CM_comment, '') AS CM_Comment, 
                      dbo.T_Campaign.CM_created, ISNULL(dbo.T_Experiments.EX_sample_concentration, 'na') AS EX_sample_concentration
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_DatasetStateName ON dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetFullDetails] TO [PNL\D3M578] AS [dbo]
GO
