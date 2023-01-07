/****** Object:  View [dbo].[V_Sample_Prep_Request_Assignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Assignment]
AS
SELECT '' AS sel,
       SPR.id,
       SPR.created,
       SPR.Estimated_Prep_Time_Days AS est_prep_time,
       SN.State_Name AS state,
       SPR.State_Comment AS state_comment,
       SPR.Request_Name AS name,
       QP.Name_with_PRN AS requester,
       SPR.priority,
       QT.days_in_queue,
       SPR.Requested_Personnel AS requested,
       SPR.Assigned_Personnel AS assigned,
       SPR.organism,
       BTO.tissue,
       SPR.Biohazard_Level AS biohazard,
       SPR.campaign,
       SPR.Number_of_Samples AS samples,
       SPR.Sample_Type AS sample_type,
       SPR.Prep_Method AS prep_method,
       -- Deprecated in June 2017: SPR.Replicates_of_Samples AS replicates,
       SPR.comment,
       SPR.reason,
       SPR.EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       Case
            When SPR.State In (4,5) Then 0          -- Request is complete or closed
            When QT.Days_In_Queue <= 30 Then 30   -- Request is 0 to 30 days old
            When QT.Days_In_Queue <= 60 Then 60   -- Request is 30 to 60 days old
            When QT.Days_In_Queue <= 90 Then 90   -- Request is 60 to 90 days old
            Else 120                                -- Request is over 90 days old
        End
        AS days_in_queue_bin
FROM T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT
       ON SPR.ID = QT.Request_ID
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON SPR.EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
      ON SPR.Tissue_ID = BTO.Identifier
WHERE (SPR.State > 0) And SPR.Request_Type = 'Default'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Assignment] TO [DDL_Viewer] AS [dbo]
GO
