/****** Object:  View [dbo].[V_Sample_Prep_Request_Active_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Active_List_Report]
AS
SELECT SPR.id,
       SPR.Request_Name AS request_name,
       SPR.created,
       SPR.Estimated_Prep_Time_Days AS est_prep_time,
       SPR.priority,
       TA.Attachments AS files,
       SN.State_Name AS state,
       SPR.State_Comment AS state_comment,
       SPR.reason,
       SPR.Number_of_Samples AS num_samples,
       SPR.Estimated_MS_runs AS ms_runs_tbg,
       QT.days_in_queue,
       SPR.Prep_Method AS prep_method,
       SPR.Requested_Personnel AS requested_personnel,
       SPR.Assigned_Personnel AS assigned_personnel,
       QP.Name_with_PRN AS requester,
       SPR.organism,
       BTO.tissue,
       SPR.Biohazard_Level AS biohazard_level,
       SPR.campaign,
       SPR.comment,
       SPR.Work_Package_Number AS work_package,
       ISNULL(CC.activation_state_name, '') AS wp_state,
       SPR.EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       SPR.Instrument_Group AS inst_group,
       SPR.Instrument_Analysis_Specifications AS inst_analysis,
       Case
            When SPR.State In (4,5) Then 0          -- Request is complete or closed
            When QT.Days_In_Queue <= 30 Then 30   -- Request is 0 to 30 days old
            When QT.Days_In_Queue <= 60 Then 60   -- Request is 30 to 60 days old
            When QT.Days_In_Queue <= 90 Then 90   -- Request is 60 to 90 days old
            Else 120                                -- Request is over 90 days old
        END AS days_in_queue_bin,
       CASE
           WHEN SPR.State <> 5 AND
                CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, then return 10 for wp_activation_state
           ELSE CC.activation_state
       END AS wp_activation_state
FROM T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT
       ON SPR.ID = QT.Request_ID
     LEFT OUTER JOIN ( SELECT Entity_ID_Value,
                              COUNT(*) AS Attachments
                       FROM T_File_Attachment
                       WHERE Entity_Type = 'sample_prep_request' AND Active > 0
                       GROUP BY Entity_ID_Value ) AS TA
       ON SPR.ID = TA.Entity_ID_Value
     LEFT OUTER JOIN V_Charge_Code_Status CC
       ON SPR.Work_Package_Number = CC.Charge_Code
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON SPR.EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
      ON SPR.Tissue_ID = BTO.Identifier
WHERE (NOT (SPR.State IN (0, 4, 5))) And SPR.Request_Type = 'Default'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Active_List_Report] TO [DDL_Viewer] AS [dbo]
GO
