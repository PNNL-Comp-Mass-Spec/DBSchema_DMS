/****** Object:  View [dbo].[V_Run_Metadata_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Run_Metadata_Export] as
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       Inst.IN_name AS Instrument,
       DTN.DST_Name AS [Type],
       DS.DS_sec_sep AS [Separation Type],
       LC.SC_Column_Number AS [LC Column],
       DSN.DSS_name AS State,
       DRN.DRN_name AS Rating,
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       DS.Scan_Count AS [Scan Count],
       DS.DS_created AS Created,
       RR.ID AS Request,
       RR.RDS_Name AS Request_Name,
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS Requested_Run_Order,
       E.Experiment_Num AS Experiment,
       PreDigest_Int_Std.Name AS [PreDigest Int Std],
       PostDigest_Int_Std.Name AS [PostDigest Int Std],
       C.Campaign_Num AS Campaign,
       DS.DS_wellplate_num AS [Wellplate Number],
       DS.DS_well_num AS [Well Number],
       U.Name_with_PRN AS Operator,
       DS.DS_comment AS [Comment],
       SPath.SP_vol_name_client + SPath.SP_path AS Storage
FROM T_Dataset DS
     INNER JOIN T_DatasetStateName DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Users U
       ON DS.DS_Oper_PRN = U.U_PRN
     INNER JOIN T_DatasetRatingName DRN
       ON DS.DS_rating = DRN.DRN_state_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Internal_Standards AS PreDigest_Int_Std
       ON E.EX_internal_standard_ID = PreDigest_Int_Std.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards AS PostDigest_Int_Std
       ON E.EX_postdigest_internal_std_ID = PostDigest_Int_Std.Internal_Std_Mix_ID
     INNER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
  


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Metadata_Export] TO [PNL\D3M578] AS [dbo]
GO
