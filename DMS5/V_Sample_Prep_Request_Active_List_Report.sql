/****** Object:  View [dbo].[V_Sample_Prep_Request_Active_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Active_List_Report]
as
SELECT SPR.ID,
       SPR.Request_Name AS RequestName,
       SPR.Created,
       SPR.Estimated_Prep_Time_Days AS [Est. Prep Time],
       SPR.Priority,
       SN.State_Name AS [State],
       SPR.State_Comment AS [State Comment],
       SPR.Reason,
       SPR.Number_of_Samples AS NumSamples,
       SPR.Estimated_MS_runs AS [MS Runs TBG],
       QT.[Days In Queue],
       SPR.Prep_Method AS PrepMethod,
       SPR.Requested_Personnel AS RequestedPersonnel,
       SPR.Assigned_Personnel AS AssignedPersonnel,
       QP.Name_with_PRN AS Requester,
       SPR.Organism,
       BTO.Tissue,
       SPR.Biohazard_Level AS BiohazardLevel,
       SPR.Campaign,
       SPR.[Comment],
       SPR.Work_Package_Number AS [Work Package],
       ISNULL(CC.Activation_State_Name, '') AS [WP State],
       SPR.EUS_Proposal_ID AS [EUS Proposal],
       EPT.Proposal_Type_Name AS [EUS Proposal Type],
       SPR.Instrument_Group AS [Inst. Group],
       SPR.Instrument_Analysis_Specifications AS [Inst. Analysis],
       Case 
            When SPR.State In (4,5) Then 0          -- Request is complete or closed
            When QT.[Days In Queue] <= 30 Then 30   -- Request is 0 to 30 days old
            When QT.[Days In Queue] <= 60 Then 60   -- Request is 30 to 60 days old
            When QT.[Days In Queue] <= 90 Then 90   -- Request is 60 to 90 days old
            Else 120                                -- Request is over 90 days old
        END AS #DaysInQueue,
       CASE
           WHEN SPR.State <> 5 AND
                CC.Activation_State >= 3 THEN 10    -- If the request is not closed, but the charge code is inactive, then return 10 for #WPActivationState
           ELSE CC.Activation_State
       END AS #WPActivationState
FROM T_Sample_Prep_Request SPR
     INNER JOIN T_Sample_Prep_Request_State_Name SN
       ON SPR.State = SN.State_ID
     LEFT OUTER JOIN T_Users AS QP
       ON SPR.Requester_PRN = QP.U_PRN
     LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT 
       ON SPR.ID = QT.Request_ID
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
