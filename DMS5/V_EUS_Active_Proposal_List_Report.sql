/****** Object:  View [dbo].[V_EUS_Active_Proposal_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Active_Proposal_List_Report]
AS
SELECT P.Proposal_ID AS [Proposal ID],
       P.Title,
       P.Proposal_Type,
       P.Proposal_Start_Date AS [Start_Date],
       P.Proposal_End_Date AS [End_Date],
       CASE
           WHEN SN.ID = 5 THEN SN.Name
           ELSE CASE
                    WHEN P.Proposal_End_Date < GETDATE() THEN 'Closed'
                    ELSE SN.Name
                END
       END AS State,
       dbo.GetProposalEUSUsersList(P.Proposal_ID, 'L', 100) AS [User Last Names]
FROM T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name SN
       ON P.State_ID = SN.ID
WHERE (P.State_ID IN (2, 5))

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Active_Proposal_List_Report] TO [DDL_Viewer] AS [dbo]
GO
