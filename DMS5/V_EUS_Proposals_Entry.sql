/****** Object:  View [dbo].[V_EUS_Proposals_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW [dbo].[V_EUS_Proposals_Entry]
AS
SELECT P.Proposal_ID AS ID,
       P.State_ID AS State,
       P.Title,
       P.Import_Date AS ImportDate,
	   P.Proposal_Type,
       dbo.GetProposalEUSUsersList(P.PROPOSAL_ID, 'I') AS EUSUsers
FROM dbo.T_EUS_Proposals P



GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Entry] TO [PNL\D3M580] AS [dbo]
GO
