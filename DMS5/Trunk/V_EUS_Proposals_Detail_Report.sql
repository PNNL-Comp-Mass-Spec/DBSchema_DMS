/****** Object:  View [dbo].[V_EUS_Proposals_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE  VIEW dbo.V_EUS_Proposals_Detail_Report
AS
SELECT P.PROPOSAL_ID AS ID, S.Name AS State, P.TITLE, P.Import_Date AS [Import Date],
dbo.GetProposalEUSUsersList(P.PROPOSAL_ID, 'N') as [EUS Users]
FROM dbo.T_EUS_Proposals P INNER JOIN
     T_EUS_Proposal_State_Name S ON P.State_ID = S.ID 




GO
