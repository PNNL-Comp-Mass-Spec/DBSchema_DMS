/****** Object:  View [dbo].[V_Sample_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Detail_Report]
AS
SELECT SPR.id,
       SPR.Request_Name AS request_name,
       QP.Name_with_PRN AS requester,
       SPR.campaign,
       SPR.reason,
       -- Deprecated in June 2017: SPR.Cell_Culture_List AS biomaterial_list,
       SPR.Material_Container_List AS material_containers,
       SPR.organism,
       BTO.Tissue AS plant_or_animal_tissue,
       -- Deprecated in June 2017: SPR.Number_Of_Biomaterial_Reps_Received AS number_of_biomaterial_reps_received,
       SPR.Biohazard_Level AS biohazard_level,
       SPR.Number_of_Samples AS number_of_samples,
       SPR.BlockAndRandomizeSamples AS block_and_randomize_samples,
       SPR.Sample_Name_List AS sample_name_list,
       SPR.Sample_Type AS sample_type,
       SPR.Prep_Method AS prep_method,
       -- Deprecated in June 2017: SPR.Replicates_of_Samples AS process_replicates,
       SPR.Special_Instructions AS special_instructions,
       SPR.comment,
       SPR.Estimated_MS_runs AS ms_runs_to_be_generated,
       -- Deprecated in June 2017: SPR.Technical_Replicates AS technical_replicates,
       SPR.Instrument_Group AS instrument_group,
       SPR.Dataset_Type AS dataset_type,
       SPR.Separation_Type AS separation_group,
       SPR.Instrument_Analysis_Specifications AS instrument_analysis_specifications,
       -- Deprecated in June 2017: SPR.UseSingleLCColumn AS use_single_lc_column,
       SPR.BlockAndRandomizeRuns AS block_and_randomize_runs,
       SPR.Sample_Naming_Convention AS sample_group_naming_prefix,
       SPR.Work_Package_Number AS work_package,
       ISNULL(CC.activation_state_name, 'Invalid') AS work_package_state,
       -- Deprecated in June 2017: SPR.Project_Number AS project_number,
       SPR.EUS_UsageType AS eus_usage_type,
       SPR.EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       CAST(EUP.Proposal_End_Date AS DATE) AS eus_proposal_end_date,
       PSN.Name AS eus_proposal_state,
       dbo.GetSamplePrepRequestEUSUsersList(SPR.id, 'V') AS eus_user,
       SPR.Requested_Personnel AS requested_personnel,
       SPR.Assigned_Personnel AS assigned_personnel,
       SPR.Estimated_Prep_Time_Days AS estimated_prep_time_days,
       -- Deprecated in June 2017: SPR.IOPSPermitsCurrent AS iops_permits_current,
       SPR.priority,
       SPR.Reason_For_High_Priority AS reason_for_high_priority,
       SN.State_Name AS state,
       SPR.State_Comment AS state_comment,
       SPR.created,
       QT.complete_or_closed,
       QT.days_in_queue,
       Case When SPR.State In (0, 4, 5) Then Null Else QT.Days_In_State End As days_in_state,
       dbo.ExperimentsFromRequest(SPR.ID) AS experiments,
       NU.updates,
       SPR.Biomaterial_Item_Count AS biomaterial_item_count,
       SPR.Experiment_Item_Count AS experiment_item_count,
       SPR.Experiment_Group_Item_Count AS experiment_group_item_count,
       SPR.Material_Containers_Item_Count AS material_containers_item_count,
       SPR.Requested_Run_Item_Count AS requested_run_item_count,
       SPR.Dataset_Item_Count AS dataset_item_count,
       SPR.HPLC_Runs_Item_Count AS hplc_runs_item_count,
       SPR.total_item_count,
       CASE
       WHEN SPR.State <> 5 AND
            CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, return 10 for wp_activation_state
       ELSE CC.activation_state
       END AS wp_activation_state
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name AS SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN ( SELECT Request_ID, COUNT(*) AS Updates
                       FROM T_Sample_Prep_Request_Updates
                       GROUP BY Request_ID ) AS NU
       ON SPR.ID = NU.Request_ID
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
       ON SPR.ID = QT.Request_ID
     LEFT OUTER JOIN V_Charge_Code_Status AS CC
       ON SPR.Work_Package_Number = CC.Charge_Code
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON SPR.EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN T_EUS_Proposal_State_Name PSN
       ON EUP.State_ID = PSN.ID
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON SPR.Tissue_ID = BTO.Identifier
WHERE SPR.Request_Type = 'Default'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
