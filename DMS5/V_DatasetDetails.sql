/****** Object:  View [dbo].[V_DatasetDetails] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.V_DatasetDetails ******/

/****** Object:  View dbo.V_DatasetDetails    Script Date: 1/17/2001 2:15:34 PM ******/
CREATE VIEW dbo.V_DatasetDetails
AS
SELECT T_Dataset.Dataset_Num, T_Dataset.DS_created, 
   T_Instrument_Name.IN_name, T_DatasetStateName.DSS_name, 
   T_Dataset.DS_comment, T_Dataset.DS_folder_name, 
   t_storage_path.SP_path, t_storage_path.SP_vol_name_server, 
   t_storage_path.SP_vol_name_client, 
   T_DatasetTypeName.DST_name, T_Dataset.DS_sec_sep, 
   T_Dataset.DS_well_num, T_Dataset.DS_Oper_PRN, 
   T_Dataset.Dataset_ID
FROM T_DatasetStateName INNER JOIN
   T_Dataset ON 
   T_DatasetStateName.Dataset_state_ID = T_Dataset.DS_state_ID INNER
    JOIN
   t_storage_path ON 
   T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER
    JOIN
   T_DatasetTypeName ON 
   T_Dataset.DS_type_ID = T_DatasetTypeName.DST_Type_ID INNER
    JOIN
   T_Instrument_Name ON 
   T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetDetails] TO [PNL\D3M578] AS [dbo]
GO
