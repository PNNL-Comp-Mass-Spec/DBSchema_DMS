/****** Object:  View [dbo].[V_Requested_Run_Admin_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Admin_Report] 
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       ISNULL(DatasetInstrument.IN_name, '') AS Instrument,
       RR.RDS_instrument_group AS [Inst. Group],
       DTN.DST_name AS [Type],
       RR.RDS_Sec_Sep AS [Separation Group],
       RR.RDS_Origin AS Origin,
       RR.RDS_Status AS Status,
       U.U_Name AS Requester,
       RR.RDS_WorkPackage AS WPN,
       ISNULL(CC.Activation_State_Name, '') AS [WP_State],
       QT.[Days In Queue],
       QS.Queue_State_Name AS [Queue State],
       ISNULL(AssignedInstrument.IN_name, '') AS [Queued Instrument],
       RR.Queue_Date AS [Queue Date],
       RR.RDS_priority AS Pri,
       RR.RDS_BatchID AS Batch,
       RR.RDS_comment AS [Comment],
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
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Requested_Run_Queue_State QS 
       ON RR.Queue_State = QS.Queue_State
     LEFT OUTER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_Instrument_Name AS DatasetInstrument
       ON DS.DS_instrument_name_ID = DatasetInstrument.Instrument_ID
     LEFT OUTER JOIN T_Instrument_Name AS AssignedInstrument
       ON RR.Queue_Instrument_ID = AssignedInstrument.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times AS QT
       ON RR.ID = QT.RequestedRun_ID
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON RR.RDS_WorkPackage = CC.Charge_Code


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Admin_Report] TO [DDL_Viewer] AS [dbo]
GO
