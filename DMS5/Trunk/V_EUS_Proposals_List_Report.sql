/****** Object:  View [dbo].[V_EUS_Proposals_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposals_List_Report]
AS
SELECT DISTINCT P.PROPOSAL_ID AS ID,
                S.Name AS State,
                dbo.GetProposalEUSUsersList(P.PROPOSAL_ID, 'N') AS Users,
                P.TITLE,
                P.Import_Date AS [Import Date],
                P.Call_Type               
FROM T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name S
       ON P.State_ID = S.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_List_Report] TO [PNL\D3M580] AS [dbo]
GO
