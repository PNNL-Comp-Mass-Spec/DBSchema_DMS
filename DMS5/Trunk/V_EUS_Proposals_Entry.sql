/****** Object:  View [dbo].[V_EUS_Proposals_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE  VIEW dbo.V_EUS_Proposals_Entry
AS
SELECT P.PROPOSAL_ID AS ID, P.State_ID AS State, P.TITLE, P.Import_Date AS ImportDate,
dbo.GetProposalEUSUsersList(P.PROPOSAL_ID, 'I') as EUSUsers
FROM dbo.T_EUS_Proposals P 





GO
