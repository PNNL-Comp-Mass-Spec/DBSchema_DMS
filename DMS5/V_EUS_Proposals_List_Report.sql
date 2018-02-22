/****** Object:  View [dbo].[V_EUS_Proposals_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposals_List_Report]
AS
SELECT DISTINCT EUP.Proposal_ID AS ID,
                S.Name AS State,
                dbo.GetProposalEUSUsersList(EUP.Proposal_ID, 'N', 125) AS Users,
                EUP.Title,
                EUP.Import_Date AS [Import Date],
                EUP.Proposal_Type AS [Proposal Type],
                EPT.Proposal_Type_Name AS [Type Name],
                EPT.Abbreviation,
                EUP.Numeric_ID
FROM T_EUS_Proposals EUP
     INNER JOIN T_EUS_Proposal_State_Name S
       ON EUP.State_ID = S.ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [DDL_Viewer] AS [dbo]
GO
