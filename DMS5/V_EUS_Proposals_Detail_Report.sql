/****** Object:  View [dbo].[V_EUS_Proposals_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW [dbo].[V_EUS_Proposals_Detail_Report]
AS
SELECT P.Proposal_ID AS ID,
       S.Name AS State,
       P.Title,
       P.Proposal_Type,
       P.Proposal_Start_Date,
       P.Proposal_End_Date,
       P.Import_Date AS [Import Date],
       P.Last_Affected,
       dbo.GetProposalEUSUsersList(P.Proposal_ID, 'V') AS [EUS Users]
FROM dbo.T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name S
       ON P.State_ID = S.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
