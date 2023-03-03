/****** Object:  View [dbo].[V_DatasetDetails] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DatasetDetails]
AS
SELECT T_Dataset.Dataset_Num, T_Dataset.DS_created,
   T_Instrument_Name.IN_name, T_Dataset_State_Name.DSS_name,
   T_Dataset.DS_comment, T_Dataset.DS_folder_name,
   t_storage_path.SP_path, t_storage_path.SP_vol_name_server,
   t_storage_path.SP_vol_name_client,
   T_Dataset_Type_Name.DST_name, T_Dataset.DS_sec_sep,
   T_Dataset.DS_well_num, T_Dataset.DS_Oper_PRN AS DS_Oper_Username,
   T_Dataset.Dataset_ID
FROM T_Dataset_State_Name INNER JOIN
   T_Dataset ON
   T_Dataset_State_Name.Dataset_state_ID = T_Dataset.DS_state_ID INNER
    JOIN
   t_storage_path ON
   T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER
    JOIN
   T_Dataset_Type_Name ON
   T_Dataset.DS_type_ID = T_Dataset_Type_Name.DST_Type_ID INNER
    JOIN
   T_Instrument_Name ON
   T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetDetails] TO [DDL_Viewer] AS [dbo]
GO
