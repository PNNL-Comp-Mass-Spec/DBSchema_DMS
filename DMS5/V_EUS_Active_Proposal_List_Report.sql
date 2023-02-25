/****** Object:  View [dbo].[V_EUS_Active_Proposal_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Active_Proposal_List_Report]
AS
SELECT P.Proposal_ID AS proposal_id,
       P.title,
       P.proposal_type,
       P.Proposal_Start_Date AS start_date,
       P.Proposal_End_Date AS end_date,
       CASE
           WHEN SN.ID = 5 THEN SN.name
           ELSE CASE
                    WHEN P.Proposal_End_Date < GETDATE() THEN 'Closed'
                    ELSE SN.name
                END
       END AS state,
       dbo.get_proposal_eus_users_list(P.proposal_id, 'L', 100) AS user_last_names
FROM T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name SN
       ON P.State_ID = SN.ID
WHERE (P.State_ID IN (2, 5))

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Active_Proposal_List_Report] TO [DDL_Viewer] AS [dbo]
GO
