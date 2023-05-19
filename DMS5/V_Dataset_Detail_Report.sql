/****** Object:  View [dbo].[V_Dataset_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Detail_Report]
AS
SELECT dbo.T_Dataset.Dataset_Num AS dataset, dbo.T_Experiments.Experiment_Num AS experiment, dbo.T_Instrument_Name.IN_name AS instrument,
       dbo.T_Dataset.DS_created AS created, dbo.T_Dataset_State_Name.DSS_name AS state, dbo.T_Dataset_Type_Name.DST_name AS type,
       dbo.T_Dataset.DS_comment AS comment, dbo.T_Dataset.DS_Oper_PRN AS operator, dbo.T_Dataset.DS_well_num AS well,
       dbo.T_Dataset.DS_sec_sep AS separation_type, dbo.T_Dataset.DS_folder_name AS folder_name,
       dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS storage, dbo.T_Instrument_Name.IN_class AS inst_class
FROM dbo.T_Dataset INNER JOIN
     dbo.T_Dataset_State_Name ON dbo.T_Dataset.DS_state_ID = dbo.T_Dataset_State_Name.Dataset_state_ID INNER JOIN
     dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
     dbo.T_Dataset_Type_Name ON dbo.T_Dataset.DS_type_ID = dbo.T_Dataset_Type_Name.DST_Type_ID INNER JOIN
     dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
     dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
