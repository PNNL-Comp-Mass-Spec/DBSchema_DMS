/****** Object:  View [dbo].[V_Dataset_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Detail_Report]
AS
SELECT dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Instrument_Name.IN_name AS Instrument,
       dbo.T_Dataset.DS_created AS Created, dbo.T_Dataset_State_Name.DSS_name AS State, dbo.T_Dataset_Type_Name.DST_name AS Type,
       dbo.T_Dataset.DS_comment AS Comment, dbo.T_Dataset.DS_Oper_PRN AS Operator, dbo.T_Dataset.DS_well_num AS Well,
       dbo.T_Dataset.DS_sec_sep AS Separation_Type, dbo.T_Dataset.DS_folder_name AS Folder_Name,
       dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS Storage, dbo.T_Instrument_Name.IN_class AS Inst_class
FROM dbo.T_Dataset INNER JOIN
     dbo.T_Dataset_State_Name ON dbo.T_Dataset.DS_state_ID = dbo.T_Dataset_State_Name.Dataset_state_ID INNER JOIN
     dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
     dbo.T_Dataset_Type_Name ON dbo.T_Dataset.DS_type_ID = dbo.T_Dataset_Type_Name.DST_Type_ID INNER JOIN
     dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
     dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
