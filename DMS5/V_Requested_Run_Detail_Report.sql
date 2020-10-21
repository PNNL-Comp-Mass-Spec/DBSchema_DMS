/****** Object:  View [dbo].[V_Requested_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Detail_Report]
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_Status AS [Status],
       -- Priority is a legacy field; do not show it (All requests since January 2011 have had Priority = 0): RR.RDS_priority AS Pri,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       -- Deprecated in December 2017 since no longer used: dbo.ExpSampleLocation(RR.Exp_ID) AS [Sample Storage],
       ML.Tag AS [Staging Location],
       InstName.IN_Name AS [Instrument Used],
       RR.RDS_instrument_group AS [Instrument Group],
       DTN.DST_Name AS [Type],
       RR.RDS_Sec_Sep AS [Separation Group],
       U.Name_with_PRN AS Requestor,
       RR.RDS_Requestor_PRN AS [Username],
       RR.RDS_created AS Created,
       QT.[Days In Queue],
       RR.RDS_Origin AS Origin,
       RR.RDS_instrument_setting AS [Instrument Settings],       
       RR.RDS_Well_Plate_Num AS [Well Plate],
       RR.RDS_Well_Num AS Well,
       RR.Vialing_Conc AS [Vialing Concentration],
       RR.Vialing_Vol AS [Vialing Volume],
       RR.RDS_comment AS [Comment],
       ISNULL(FC.Factor_Count, 0) AS Factors,
       RRB.Batch AS [Batch Name],
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order],
       LC.Cart_Name AS Cart,
       CartConfig.Cart_Config_Name AS [Cart Config],
       RR.RDS_Cart_Col AS [Column Number],
       RR.RDS_WorkPackage [Work Package],
       CASE WHEN RR.RDS_WorkPackage IN ('none', '') THEN ''
            ELSE ISNULL(CC.Activation_State_Name, 'Invalid') 
            END AS [Work Package State],
       EUT.Name AS [EUS Usage Type],
       RR.RDS_EUS_Proposal_ID AS [EUS Proposal],
       EPT.Proposal_Type_Name AS [EUS Proposal Type],
       CAST(EUP.Proposal_End_Date AS DATE) AS [EUS Proposal End Date],
       PSN.Name AS [EUS Proposal State],
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'V') AS [EUS User],
       dbo.T_Attachments.Attachment_Name AS [MRM Transistion List],
       RR.RDS_note AS Note,
       RR.RDS_special_instructions AS [Special Instructions],
       Case
           When RR.RDS_Status = 'Active' AND
                CC.Activation_State >= 3 THEN 10    -- If the requested run is active, but the charge code is inactive, then return 10 for #WPActivationState
           Else CC.Activation_State
       End AS #WPActivationState
FROM dbo.T_DatasetTypeName AS DTN
     INNER JOIN dbo.T_Requested_Run AS RR
                INNER JOIN dbo.T_Experiments AS E
                  ON RR.Exp_ID = E.Exp_ID
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN dbo.T_Users AS U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN dbo.T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_LC_Cart AS LC
       ON RR.RDS_Cart_ID = LC.ID
     INNER JOIN dbo.T_Requested_Run_Batches AS RRB
       ON RR.RDS_BatchID = RRB.ID
     INNER JOIN dbo.T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN dbo.T_Attachments
       ON RR.RDS_MRM_Attachment = dbo.T_Attachments.ID
     LEFT OUTER JOIN dbo.T_Dataset DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
       ON RR.RDS_Cart_Config_ID = CartConfig.Cart_Config_ID
     LEFT OUTER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times QT
       ON RR.ID = QT.RequestedRun_ID
     LEFT OUTER JOIN dbo.V_Factor_Count_By_Requested_Run FC
       ON FC.RR_ID = RR.ID
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON RR.RDS_WorkPackage = CC.Charge_Code
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN T_EUS_Proposal_State_Name PSN
       ON EUP.State_ID = PSN.ID
     LEFT OUTER JOIN T_Material_Locations ML
       ON RR.Location_ID = ML.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
