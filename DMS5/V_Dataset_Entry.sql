/****** Object:  View [dbo].[V_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Entry]
AS
SELECT  T_Experiments.Experiment_Num ,
        TIN.IN_name AS DS_Instrument_Name ,
        TDTN.DST_name AS DS_type_name ,
        TDS.Dataset_Num ,
        TDS.DS_folder_name ,
        TDS.DS_Oper_PRN ,
        TDS.DS_wellplate_num ,
        TDS.DS_well_num ,
        TDS.DS_sec_sep ,
        TDS.DS_comment ,
        TDRN.DRN_name AS DS_Rating ,
        0 AS DS_Request ,
        TLC.SC_Column_Number AS DS_Column ,
        TIS.Name AS DS_internal_standard ,
        TEUT.Name AS DS_EUSUsageType ,
        TRR.RDS_EUS_Proposal_ID AS DS_EUSProposalID ,
        dbo.GetRequestedRunEUSUsersList(TRR.ID, 'I') AS DS_EUSUsers ,
        TCRT.Cart_Name AS DS_LCCartName,
		TDS.Capture_Subfolder AS Capture_Subfolder
FROM    T_Dataset TDS
        INNER JOIN T_Experiments ON TDS.Exp_ID = T_Experiments.Exp_ID
        INNER JOIN T_DatasetTypeName TDTN ON TDS.DS_type_ID = TDTN.DST_Type_ID
        INNER JOIN T_Instrument_Name TIN ON TDS.DS_instrument_name_ID = TIN.Instrument_ID
        INNER JOIN T_DatasetRatingName TDRN ON TDS.DS_rating = TDRN.DRN_state_ID
        INNER JOIN T_LC_Column TLC ON TDS.DS_LC_column_ID = TLC.ID
        INNER JOIN T_Internal_Standards TIS ON TDS.DS_internal_standard_ID = TIS.Internal_Std_Mix_ID
LEFT OUTER JOIN dbo.T_Requested_Run TRR ON TRR.DatasetID = TDS.Dataset_ID 
LEFT outer JOIN dbo.T_LC_Cart TCRT ON TCRT.ID = TRR.RDS_Cart_ID
LEFT OUTER JOIN dbo.T_EUS_UsageType TEUT ON TRR.RDS_EUS_UsageType = TEUT.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Entry] TO [DDL_Viewer] AS [dbo]
GO
