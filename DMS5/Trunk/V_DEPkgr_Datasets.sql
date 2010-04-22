/****** Object:  View [dbo].[V_DEPkgr_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Datasets
AS
SELECT     TOP (100) PERCENT dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.Dataset_Num AS Dataset_Name, dbo.T_Dataset.DS_comment AS Comments, 
                      dbo.T_Dataset.DS_created AS Created_Date, dbo.T_Instrument_Class.IN_class AS Instrument_Class, 
                      dbo.T_DatasetTypeName.DST_Name AS Dataset_Type, dbo.T_Dataset.Exp_ID AS Experiment_ID, 
                      dbo.T_Experiments.Experiment_Num AS Experiment_Name, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path + dbo.T_Dataset.Dataset_Num + '\' AS Dataset_Path, 
                      dbo.T_Archive_Path.AP_archive_path + '/' + dbo.T_Dataset.Dataset_Num + '/' AS Archive_Path, 
                      dbo.T_DatasetArchiveStateName.DASN_StateName AS Archive_State, dbo.T_DatasetStateName.DSS_name AS Dataset_State, 
                      dbo.T_Requested_Run.ID AS Request_ID, dbo.T_Dataset.DS_LC_column_ID AS LC_Column_ID, 
                      dbo.T_Dataset.Acq_Time_Start AS Acquisition_Time
FROM         dbo.t_storage_path INNER JOIN
                      dbo.T_Dataset INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID ON 
                      dbo.t_storage_path.SP_path_ID = dbo.T_Dataset.DS_storage_path_ID INNER JOIN
                      dbo.T_DatasetStateName ON dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID INNER JOIN
                      dbo.T_Requested_Run ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run.DatasetID LEFT OUTER JOIN
                      dbo.T_DatasetArchiveStateName INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_DatasetArchiveStateName.DASN_StateID = dbo.T_Dataset_Archive.AS_state_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID ON 
                      dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID
ORDER BY dbo.T_Dataset.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Datasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Datasets] TO [PNL\D3M580] AS [dbo]
GO
