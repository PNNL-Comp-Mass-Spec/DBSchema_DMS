/****** Object:  View [dbo].[V_Requested_Run_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_List_Report_2]
AS
SELECT RR.ID AS request,
       RR.RDS_Name AS name,
       RR.RDS_Status AS status,
       RR.RDS_Origin AS origin,
       -- Priority is a legacy field; do not show it (All requests since January 2011 have had Priority = 0): RR.RDS_priority AS pri,
       ISNULL(DS.acq_time_start, RR.RDS_Run_Start) AS acq_start,
       RR.RDS_BatchID AS batch,
       C.Campaign_Num AS campaign,
       E.Experiment_Num AS experiment,
       DS.Dataset_Num AS dataset,
       ISNULL(InstName.in_name, '') AS instrument,
       RR.RDS_instrument_group AS inst_group,
       U.U_Name AS requester,
       RR.RDS_created AS created,
       QT.days_in_queue,
       QS.Queue_State_Name AS queue_state,
       ISNULL(AssignedInstrument.in_name, '') AS queued_instrument,
       RR.RDS_WorkPackage AS work_package,
       ISNULL(CC.activation_state_name, '') AS wp_state,
       EUT.Name AS usage,
       RR.RDS_EUS_Proposal_ID AS proposal,
       EPT.Abbreviation AS proposal_type,
       -- Deprecated 2020-06-26: EPT.Proposal_Type_Name AS eus_proposal_type,
       PSN.Name AS proposal_state,
       RR.RDS_comment AS comment,
       DTN.DST_name AS type,
       RR.RDS_Sec_Sep AS separation_group,
       RR.RDS_Well_Plate_Num AS wellplate,
       RR.RDS_Well_Num AS well,
       RR.Vialing_Conc AS vialing_conc,
       RR.Vialing_Vol AS vialing_vol,
       ML.Tag AS staging_location,
       RR.RDS_Block AS block,
       RR.RDS_Run_Order AS run_order,
       LC.Cart_Name AS cart,
       CartConfig.Cart_Config_Name AS cart_config,
       -- Deprecated 2020-10-21: CONVERT(varchar(12), RR.RDS_Cart_Col) AS col,
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
                CC.Activation_State >= 3 THEN 10    -- If the requested run is active, but the charge code is inactive, then return 10 for wp_activation_state
           ELSE CC.activation_state
       END AS wp_activation_state
FROM T_Requested_Run AS RR
     INNER JOIN T_Dataset_Type_Name AS DTN
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
       ON RR.ID = QT.Requested_Run_ID
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
