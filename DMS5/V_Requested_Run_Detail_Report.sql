/****** Object:  View [dbo].[V_Requested_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Detail_Report]
AS
SELECT RR.ID AS request,
       RR.RDS_Name AS name,
       RR.RDS_Status AS status,
       -- Priority is a legacy field; do not show it (All requests since January 2011 have had Priority = 0): RR.RDS_priority AS pri,
       C.Campaign_Num AS campaign,
       E.Experiment_Num AS experiment,
       DS.Dataset_Num AS dataset,
       -- Deprecated in December 2017 since no longer used: dbo.ExpSampleLocation(RR.Exp_ID) AS sample_storage,
       ML.Tag AS staging_location,
       InstName.IN_Name AS instrument_used,
       RR.RDS_instrument_group AS instrument_group,
       DTN.DST_Name AS run_type,
       RR.RDS_Sec_Sep AS separation_group,
       U.Name_with_PRN AS requester,
       RR.RDS_Requestor_PRN As username,
       RR.RDS_created AS created,
       QT.Days_In_Queue As days_in_queue,
       QS.Queue_State_Name AS queue_state,
       ISNULL(AssignedInstrument.in_name, '') AS queued_instrument,
       RR.RDS_Origin AS origin,
       RR.RDS_instrument_setting AS instrument_settings,
       RR.RDS_Well_Plate_Num AS wellplate,
       RR.RDS_Well_Num AS well,
       RR.Vialing_Conc AS vialing_concentration,
       RR.Vialing_Vol AS vialing_volume,
       RR.RDS_comment AS comment,
       ISNULL(FC.factor_count, 0) AS factors,
       RRB.Batch AS batch_name,
       RR.RDS_BatchID AS batch,
       -- Deprecated in 2021 since no longer used: RR.RDS_Blocking_Factor AS blocking_factor,
       RR.RDS_Block AS block,
       RR.RDS_Run_Order AS run_order,
       LC.Cart_Name AS cart,
       CartConfig.Cart_Config_Name AS cart_config,
       RR.RDS_Cart_Col AS column_name,
       RR.RDS_WorkPackage Work_Package,
       CASE WHEN RR.RDS_WorkPackage IN ('none', '') THEN ''
            ELSE ISNULL(CC.activation_state_name, 'Invalid')
            END AS work_package_state,
       EUT.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       CAST(EUP.Proposal_End_Date AS DATE) AS eus_proposal_end_date,
       PSN.Name AS eus_proposal_state,
       dbo.GetRequestedRunEUSUsersList(RR.id, 'V') AS eus_user,
       dbo.T_Attachments.Attachment_Name AS mrm_transition_list,
       RR.RDS_note AS note,
       RR.RDS_special_instructions AS special_instructions,
       Case
           When RR.RDS_Status = 'Active' AND
                CC.Activation_State >= 3 THEN 10    -- If the requested run is active, but the charge code is inactive, then return 10 for wp_activation_state
           Else CC.activation_state
       End AS wp_activation_state
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
     INNER JOIN T_Requested_Run_Queue_State QS
       ON RR.Queue_State = QS.Queue_State
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
     LEFT OUTER JOIN T_Instrument_Name AS AssignedInstrument
       ON RR.Queue_Instrument_ID = AssignedInstrument.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times QT
       ON RR.ID = QT.Requested_Run_ID
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
