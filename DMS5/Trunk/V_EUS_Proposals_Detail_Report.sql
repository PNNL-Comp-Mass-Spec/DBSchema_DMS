/****** Object:  View [dbo].[V_EUS_Proposals_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW [dbo].[V_EUS_Proposals_Detail_Report]
AS
SELECT P.PROPOSAL_ID AS ID,
       S.Name AS State,
       P.Title,
       P.Import_Date AS [Import Date],
       dbo.GetProposalEUSUsersList(P.PROPOSAL_ID, 'N') AS [EUS Users]
FROM dbo.T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name S
       ON P.State_ID = S.ID





GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
