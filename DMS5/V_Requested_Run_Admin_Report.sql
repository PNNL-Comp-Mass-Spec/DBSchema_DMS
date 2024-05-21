/****** Object:  View [dbo].[V_Requested_Run_Admin_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Admin_Report]
AS
SELECT RR.ID AS request,
       RR.RDS_Name AS name,
       C.Campaign_Num AS campaign,
       E.Experiment_Num AS experiment,
       DS.Dataset_Num AS dataset,
       ISNULL(DatasetInstrument.in_name, '') AS instrument,
       RR.RDS_instrument_group AS inst_group,
       DTN.DST_name AS type,
       RR.RDS_Sec_Sep AS separation_group,
       RR.RDS_Origin AS origin,
       RR.RDS_Status AS status,
       U.U_Name AS requester,
       RR.RDS_WorkPackage AS wpn,
       ISNULL(CCA.Activation_State_Name, '') AS wp_state,
       QT.days_in_queue,
       QS.Queue_State_Name AS queue_state,
       ISNULL(AssignedInstrument.in_name, '') AS queued_instrument,
       RR.Queue_Date AS queue_date,
       RR.RDS_priority AS priority,
       RR.RDS_BatchID AS batch,
       RR.RDS_Block AS block,
       RR.RDS_Run_Order AS run_order,
       RR.RDS_comment AS comment,
       DS.DS_Comment AS dataset_comment,
       RR.RDS_NameCode AS request_name_code,
       CASE
           WHEN RR.RDS_Status <> 'Active' THEN 0
           WHEN QT.Days_In_Queue <= 30 THEN 30
           WHEN QT.Days_In_Queue <= 60 THEN 60
           WHEN QT.Days_In_Queue <= 90 THEN 90
           ELSE 120
       END AS days_in_queue_bin,
       CASE
           WHEN RR.RDS_Status = 'Active' AND
                RR.Cached_WP_Activation_State >= 3 THEN 10    -- If the requested run is active, but the charge code is inactive, return 10 for wp_activation_state
           ELSE RR.Cached_WP_Activation_State
       END AS wp_activation_state
FROM T_Requested_Run AS RR
     INNER JOIN T_Dataset_Type_Name AS DTN
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users AS U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Requested_Run_Queue_State QS
       ON RR.Queue_State = QS.Queue_State
     INNER JOIN T_Charge_Code_Activation_State CCA
       ON RR.Cached_WP_Activation_State = CCA.Activation_State
     LEFT OUTER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_Instrument_Name AS DatasetInstrument
       ON DS.DS_instrument_name_ID = DatasetInstrument.Instrument_ID
     LEFT OUTER JOIN T_Instrument_Name AS AssignedInstrument
       ON RR.Queue_Instrument_ID = AssignedInstrument.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times AS QT
       ON RR.ID = QT.Requested_Run_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Admin_Report] TO [DDL_Viewer] AS [dbo]
GO
