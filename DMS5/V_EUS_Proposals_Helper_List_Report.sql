/****** Object:  View [dbo].[V_EUS_Proposals_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposals_Helper_List_Report]
AS
SELECT P.Proposal_ID AS [Proposal ID],
       P.Title,
       ISNULL(CONVERT(varchar(16), RR.ID), '(none yet)') AS Request,
       ISNULL(DS.Dataset_Num, '(none yet)') AS Dataset,
       P.Proposal_Type
FROM T_Dataset DS
     INNER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     RIGHT OUTER JOIN T_EUS_Proposals P
       ON RR.RDS_EUS_Proposal_ID = P.Proposal_ID
WHERE (P.State_ID IN (2, 5))


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Helper_List_Report] TO [PNL\D3M578] AS [dbo]
GO
