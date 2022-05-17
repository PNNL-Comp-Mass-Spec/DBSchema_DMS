/****** Object:  View [dbo].[V_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Entry]
AS
SELECT E.Experiment_Num AS experiment,
       Inst.IN_name AS instrument_name,
       DTN.DST_name AS dataset_type,
       DS.Dataset_Num AS dataset,
       DS.DS_folder_name AS folder_name,
       DS.DS_Oper_PRN AS operator_prn,
       DS.DS_wellplate_num AS wellplate,
       DS.DS_well_num AS well,
       DS.DS_sec_sep AS separation_type,
       DS.DS_comment AS comment,
       DSRating.DRN_name AS dataset_rating,
       0 AS request_id,
       LCCol.SC_Column_Number AS lc_column,
       IntStd.Name AS internal_standard,
       EUSUsage.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal_id,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS eus_users,
       LCCart.Cart_Name AS lc_cart_name,
       CartConfig.Cart_Config_Name AS lc_cart_config,
       DS.Capture_Subfolder AS capture_subfolder,
	   DS.dataset_id
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_LC_Column LCCol
       ON DS.DS_LC_column_ID = LCCol.ID
     INNER JOIN T_Internal_Standards IntStd
       ON DS.DS_internal_standard_ID = IntStd.Internal_Std_Mix_ID
     LEFT OUTER JOIN dbo.T_Requested_Run RR
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_LC_Cart LCCart
       ON LCCart.ID = RR.RDS_Cart_ID
     LEFT OUTER JOIN dbo.T_EUS_UsageType EUSUsage
       ON RR.RDS_EUS_UsageType = EUSUsage.ID
     LEFT OUTER JOIN T_LC_Cart_Configuration CartConfig
       ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Entry] TO [DDL_Viewer] AS [dbo]
GO
