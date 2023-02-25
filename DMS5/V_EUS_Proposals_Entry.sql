/****** Object:  View [dbo].[V_EUS_Proposals_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Proposals_Entry]
AS
SELECT P.Proposal_ID AS id,
       P.State_ID AS state,
       P.title,
       P.import_date,
       P.proposal_type,
       P.Proposal_ID_AutoSupersede As superseded_by,
       dbo.get_proposal_eus_users_list(P.PROPOSAL_ID, 'I', 1000) AS eus_users
FROM dbo.T_EUS_Proposals P

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Entry] TO [DDL_Viewer] AS [dbo]
GO
