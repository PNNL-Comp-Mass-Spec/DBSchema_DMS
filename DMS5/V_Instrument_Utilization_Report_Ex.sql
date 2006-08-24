/****** Object:  View [dbo].[V_Instrument_Utilization_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Instrument_Utilization_Report_Ex
AS
SELECT     T_Instrument_Name.IN_name AS Instrument, T_Dataset.DS_instrument_name_ID AS Instrument_ID, T_Dataset.Dataset_Num AS Dataset, 
                      T_Dataset.Dataset_ID AS Dataset_ID, NULL AS Run_Start, T_Dataset.DS_created AS Run_Finish, T_Requested_Run_History.ID AS Request, 
                      T_Requested_Run_History.RDS_Oper_PRN AS Requester, 
                      t_storage_path.SP_vol_name_client + t_storage_path.SP_path + T_Dataset.DS_folder_name as DatasetFolder
FROM         T_Dataset INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_DatasetTypeName ON T_Dataset.DS_type_ID = T_DatasetTypeName.DST_Type_ID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID LEFT OUTER JOIN
                      T_Requested_Run_History ON T_Dataset.Dataset_ID = T_Requested_Run_History.DatasetID
WHERE     (T_Dataset.DS_state_ID = 3)

GO
