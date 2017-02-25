/****** Object:  View [dbo].[V_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Entry]
AS
SELECT T_Experiments.Experiment_Num,
       Inst.IN_name AS DS_Instrument_Name,
       DTN.DST_name AS DS_type_name,
       DS.Dataset_Num,
       DS.DS_folder_name,
       DS.DS_Oper_PRN,
       DS.DS_wellplate_num,
       DS.DS_well_num,
       DS.DS_sec_sep,
       DS.DS_comment,
       DSRating.DRN_name AS DS_Rating,
       0 AS DS_Request,
       LCCol.SC_Column_Number AS DS_Column,
       IntStd.Name AS DS_internal_standard,
       EUSUsage.Name AS DS_EUSUsageType,
       RR.RDS_EUS_Proposal_ID AS DS_EUSProposalID,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS DS_EUSUsers,
       LCCart.Cart_Name AS DS_LCCartName,
       CartConfig.Cart_Config_Name AS LC_Cart_Config,
       DS.Capture_Subfolder AS Capture_Subfolder
FROM T_Dataset DS
     INNER JOIN T_Experiments
       ON DS.Exp_ID = T_Experiments.Exp_ID
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
