/****** Object:  View [dbo].[V_Requested_Run_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_List_Report_2] 
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_Status AS Status,
       RR.RDS_Origin AS Origin,
       -- Priority is a legacy field; do not show it (All requests since January 2011 have had Priority = 0): RR.RDS_priority AS Pri,
       ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) AS Acq_Start,
       RR.RDS_BatchID AS Batch,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       ISNULL(InstName.IN_name, '') AS Instrument,
       RR.RDS_instrument_group AS [Inst. Group],
       U.U_Name AS Requestor,
       RR.RDS_created AS Created,
       QT.[Days In Queue],
       QS.Queue_State_Name AS [Queue State],
       ISNULL(AssignedInstrument.IN_name, '') AS [Queued Instrument],
       RR.RDS_WorkPackage AS [Work Package],
       ISNULL(CC.Activation_State_Name, '') AS [WP State],
       EUT.Name AS [Usage],
       RR.RDS_EUS_Proposal_ID AS Proposal,
       EPT.Abbreviation AS [Proposal Type],
       -- Deprecated 2020-06-26: EPT.Proposal_Type_Name AS [EUS Proposal Type],
       PSN.Name AS [Proposal State],
       RR.RDS_comment AS [Comment],
       DTN.DST_name AS [Type],
       RR.RDS_Sec_Sep AS [Separation Group],
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.Vialing_Conc AS [Vialing Conc],
       RR.Vialing_Vol AS [Vialing Vol],
       ML.Tag AS [Staging Location],
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order],
       LC.Cart_Name AS Cart,
       CartConfig.Cart_Config_Name AS [Cart Config],
       -- Deprecated 2020-10-21: CONVERT(varchar(12), RR.RDS_Cart_Col) AS Col,
       DS.DS_Comment AS [Dataset Comment],
       RR.RDS_NameCode AS [Request Name Code],
       CASE
           WHEN RR.RDS_Status <> 'Active' THEN 0
           WHEN QT.[Days In Queue] <= 30 THEN 30
           WHEN QT.[Days In Queue] <= 60 THEN 60
           WHEN QT.[Days In Queue] <= 90 THEN 90
           ELSE 120
       END AS [#DaysInQueue],
       CASE
           WHEN RR.RDS_Status = 'Active' AND
                CC.Activation_State >= 3 THEN 10    -- If the requested run is active, but the charge code is inactive, then return 10 for #WPActivationState
           ELSE CC.Activation_State
       END AS #WPActivationState
FROM T_Requested_Run AS RR
     INNER JOIN T_DatasetTypeName AS DTN
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users AS U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_LC_Cart AS LC
       ON RR.RDS_Cart_ID = LC.ID
     INNER JOIN T_Requested_Run_Queue_State QS 
       ON RR.Queue_State = QS.Queue_State
     LEFT OUTER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
       ON RR.RDS_Cart_Config_ID = CartConfig.Cart_Config_ID
     LEFT OUTER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN T_Instrument_Name AS AssignedInstrument
       ON RR.Queue_Instrument_ID = AssignedInstrument.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times AS QT
       ON RR.ID = QT.RequestedRun_ID
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
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
