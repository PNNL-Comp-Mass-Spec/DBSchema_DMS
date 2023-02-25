/****** Object:  View [dbo].[V_EUS_Proposals_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Proposals_List_Report]
AS
SELECT DISTINCT EUP.Proposal_ID AS id,
                S.Name AS state,
                dbo.get_proposal_eus_users_list(EUP.proposal_id, 'N', 125) AS users,
                EUP.title,
                EUP.Import_Date AS import_date,
                EUP.Proposal_Start_Date AS start_date,
                EUP.Proposal_End_Date AS end_date,
                EPT.Proposal_Type_Name AS proposal_type,
                EPT.abbreviation,
                EUP.numeric_id,
                EUP.Proposal_ID_AutoSupersede As superseded_by
FROM T_EUS_Proposals EUP
     INNER JOIN T_EUS_Proposal_State_Name S
       ON EUP.State_ID = S.ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [DDL_Viewer] AS [dbo]
GO
