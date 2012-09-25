/****** Object:  View [dbo].[V_Run_Metadata_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Run_Metadata_Export as
SELECT
  T_Dataset.Dataset_ID AS ID,
  T_Dataset.Dataset_Num AS Dataset,
  T_Instrument_Name.IN_name AS Instrument,
  T_DatasetTypeName.DST_Name AS Type,
  T_Dataset.DS_sec_sep AS [Separation Type],
  T_LC_Column.SC_Column_Number AS [LC Column],
  T_DatasetStateName.DSS_name AS State,
  T_DatasetRatingName.DRN_name AS Rating,
  T_Dataset.Acq_Time_Start AS [Acquisition Start],
  T_Dataset.Acq_Time_End AS [Acquisition End],
  T_Dataset.Scan_Count AS [Scan Count],
  T_Dataset.DS_created AS Created,
  T_Requested_Run.ID AS Request,
  T_Requested_Run.RDS_Name AS Request_Name,
  T_Requested_Run.RDS_Block AS Block,
  T_Requested_Run.RDS_Run_Order AS Requested_Run_Order,
  T_Experiments.Experiment_Num AS Experiment,
  PreDigest_Int_Std.Name AS [PreDigest Int Std],
  PostDigest_Int_Std.Name AS [PostDigest Int Std],
  T_Campaign.Campaign_Num AS Campaign,
  T_Dataset.DS_wellplate_num AS [Wellplate Number],
  T_Dataset.DS_well_num AS [Well Number],
  T_Users.U_Name + ' (' + T_Dataset.DS_Oper_PRN + ')' AS Operator,
  T_Dataset.DS_comment AS Comment,
  t_storage_path.SP_vol_name_client + t_storage_path.SP_path AS Storage
FROM
  T_Dataset
  INNER JOIN T_DatasetStateName ON T_Dataset.DS_state_ID = T_DatasetStateName.Dataset_state_ID
  INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
  INNER JOIN T_DatasetTypeName ON T_Dataset.DS_type_ID = T_DatasetTypeName.DST_Type_ID
  INNER JOIN T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
  INNER JOIN t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID
  INNER JOIN T_Users ON T_Dataset.DS_Oper_PRN = T_Users.U_PRN
  INNER JOIN T_DatasetRatingName ON T_Dataset.DS_rating = T_DatasetRatingName.DRN_state_ID
  INNER JOIN T_LC_Column ON T_Dataset.DS_LC_column_ID = T_LC_Column.ID
  INNER JOIN T_Internal_Standards AS PreDigest_Int_Std ON T_Experiments.EX_internal_standard_ID = PreDigest_Int_Std.Internal_Std_Mix_ID
  INNER JOIN T_Internal_Standards AS PostDigest_Int_Std ON T_Experiments.EX_postdigest_internal_std_ID = PostDigest_Int_Std.Internal_Std_Mix_ID
  INNER JOIN T_Requested_Run ON T_Dataset.Dataset_ID = T_Requested_Run.DatasetID
  INNER JOIN T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID  
  

GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Metadata_Export] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Metadata_Export] TO [PNL\D3M580] AS [dbo]
GO
