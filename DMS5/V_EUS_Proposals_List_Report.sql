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
                EUP.Import_Date AS [Import_Date],
                EUP.Proposal_Start_Date AS [Start_Date],
                EUP.Proposal_End_Date AS [End_Date],
                EPT.Proposal_Type_Name AS [Proposal_Type],
                EPT.Abbreviation,
                EUP.Numeric_ID,
                EUP.Proposal_ID_AutoSupersede As [Superseded_By]
FROM T_EUS_Proposals EUP
     INNER JOIN T_EUS_Proposal_State_Name S
       ON EUP.State_ID = S.ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [DDL_Viewer] AS [dbo]
GO
