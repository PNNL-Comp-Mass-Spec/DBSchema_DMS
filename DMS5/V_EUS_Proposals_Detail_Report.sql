/****** Object:  View [dbo].[V_EUS_Proposals_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW [dbo].[V_EUS_Proposals_Detail_Report]
AS
SELECT EUP.Proposal_ID AS ID,
       S.Name AS State,
       EUP.Title,
       EUP.Proposal_Type AS [Proposal Type],
       EPT.Proposal_Type_Name AS [Proposal Type Name],
       EPT.Abbreviation AS [Abbreviation],
       EUP.Proposal_Start_Date AS [Proposal Start Date],
       EUP.Proposal_End_Date AS [Proposal End Date],
       EUP.Import_Date AS [Import Date],
       EUP.Last_Affected,
       dbo.GetProposalEUSUsersList(EUP.Proposal_ID, 'V', 1000) AS [EUS Users]
FROM dbo.T_EUS_Proposals EUP
     INNER JOIN T_EUS_Proposal_State_Name S
       ON EUP.State_ID = S.ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
