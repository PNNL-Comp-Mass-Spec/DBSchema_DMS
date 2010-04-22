/****** Object:  View [dbo].[V_EUS_Proposals_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposals_List_Report]
AS
SELECT DISTINCT dbo.T_EUS_Proposals.PROPOSAL_ID AS ID,
                dbo.T_EUS_Proposal_State_Name.Name AS State,
                dbo.GetProposalEUSUsersList(dbo.T_EUS_Proposals.PROPOSAL_ID, 'N') AS Users,
                dbo.T_EUS_Proposals.Title,
                dbo.T_EUS_Proposals.Import_Date AS [Import Date]
FROM dbo.T_EUS_Proposals
     INNER JOIN dbo.T_EUS_Proposal_State_Name
       ON dbo.T_EUS_Proposals.State_ID = dbo.T_EUS_Proposal_State_Name.ID
     LEFT OUTER JOIN dbo.T_EUS_Proposal_Users
       ON dbo.T_EUS_Proposals.PROPOSAL_ID = dbo.T_EUS_Proposal_Users.Proposal_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [PNL\D3M580] AS [dbo]
GO
