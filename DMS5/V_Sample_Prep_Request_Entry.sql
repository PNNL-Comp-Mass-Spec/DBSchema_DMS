/****** Object:  View [dbo].[V_Sample_Prep_Request_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Entry]
AS
SELECT  SPR.id,
        SPR.request_name,
        SPR.requester_prn AS requester_username,
        SPR.Reason + '__NoCopy__' As reason,
        SPR.organism,
        BTO.tissue,
        SPR.biohazard_level,
        SPR.campaign,
        Cast(SPR.Number_of_Samples As Varchar(12)) + '__NoCopy__' AS number_of_samples,
        SPR.sample_name_list,
        SPR.sample_type,
        SPR.prep_method,
        SPR.sample_naming_convention,
        SPR.requested_personnel,
        SPR.assigned_personnel,
        SPR.estimated_prep_time_days,
        Cast(SPR.Estimated_MS_runs As Varchar(12)) + '__NoCopy__' AS estimated_ms_runs,
        SPR.Work_Package_Number AS work_package,
        SPR.instrument_group,
        SPR.dataset_type,
        SPR.instrument_analysis_specifications,
        SPR.[Comment] + '__NoCopy__' As comment,
        SPR.priority,
        SN.State_Name AS state,
        SPR.state_comment,
        SPR.EUS_UsageType AS eus_usage_type,
        SPR.EUS_Proposal_ID AS eus_proposal_id,
        SPR.eus_user_id,
        SPR.facility,
        SPR.Separation_Type AS separation_group,
        SPR.BlockAndRandomizeSamples AS block_and_randomize_samples,
        SPR.BlockAndRandomizeRuns AS block_and_randomize_runs,
        SPR.Reason_For_High_Priority + '__NoCopy__' AS reason_for_high_priority,
        SPR.Material_Container_List + '__NoCopy__' AS material_container_list
FROM T_Sample_Prep_Request AS SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON SPR.Tissue_ID = BTO.Identifier

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Entry] TO [DDL_Viewer] AS [dbo]
GO
