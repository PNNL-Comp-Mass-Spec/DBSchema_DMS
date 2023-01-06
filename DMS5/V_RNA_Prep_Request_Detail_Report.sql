/****** Object:  View [dbo].[V_RNA_Prep_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_RNA_Prep_Request_Detail_Report]
AS
SELECT SPR.id,
       SPR.Request_Name AS request_name,
       QP.Name_with_PRN AS requester,
       SPR.campaign,
       SPR.reason,
       -- Deprecated in August 2018: SPR.Cell_Culture_List AS biomaterial_list,
       SPR.organism,
       -- Deprecated in August 2018: SPR.Number_Of_Biomaterial_Reps_Received AS number_of_biomaterial_reps_received,
       SPR.Biohazard_Level AS biohazard_level,
       SPR.Number_of_Samples AS number_of_samples,
       SPR.Sample_Name_List AS sample_name_list,
       SPR.Sample_Type AS sample_type,
       SPR.Prep_Method AS prep_method,
       SPR.Instrument_Name AS instrument_name,
       SPR.Dataset_Type AS dataset_type,
       SPR.Instrument_Analysis_Specifications AS instrument_analysis_specifications,
       SPR.Sample_Naming_Convention AS sample_group_naming_prefix,
       SPR.Work_Package_Number AS work_package,
       ISNULL(CC.activation_state_name, 'Invalid') AS work_package_state,
       -- Deprecated in August 2018: SPR.Project_Number AS project_number,
       SPR.EUS_UsageType AS eus_usage_type,
       SPR.EUS_Proposal_ID AS eus_proposal,
       dbo.GetSamplePrepRequestEUSUsersList(SPR.id, 'V') As eus_user,
       SPR.Estimated_Completion AS estimated_completion,
       SN.State_Name AS state,
       SPR.created,
       dbo.ExperimentsFromRequest(SPR.ID) AS experiments,
       UpdateCountQ.updates,
       CASE
       WHEN SPR.State <> 5 AND
            CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, return 10 for wp_activation_state
       ELSE CC.activation_state
       END AS wp_activation_state
FROM T_Sample_Prep_Request AS spr
     INNER JOIN T_Sample_Prep_Request_State_Name AS sn
       ON SPR.State = SN.state_id
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN ( SELECT Request_ID,
                              COUNT(*) AS Updates
                       FROM T_Sample_Prep_Request_Updates
                       GROUP BY Request_ID ) AS UpdateCountQ
       ON SPR.ID = UpdateCountQ.Request_ID
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON SPR.Work_Package_Number = CC.Charge_Code
WHERE SPR.Request_Type = 'RNA'


GO
GRANT VIEW DEFINITION ON [dbo].[V_RNA_Prep_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
