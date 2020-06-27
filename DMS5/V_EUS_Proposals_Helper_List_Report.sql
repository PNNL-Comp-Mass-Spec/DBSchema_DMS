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
       P.Proposal_Type,
       CASE
           WHEN SN.ID = 5 THEN SN.Name
           ELSE CASE
                    WHEN P.Proposal_End_Date < GETDATE() THEN 'Closed'
                    ELSE SN.Name
                END
       END AS Proposal_State
FROM T_EUS_Proposals P
     INNER JOIN T_EUS_Proposal_State_Name SN
       ON P.State_ID = SN.ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON RR.RDS_EUS_Proposal_ID = P.Proposal_ID
     LEFT OUTER JOIN T_Dataset DS
       ON DS.Dataset_ID = RR.DatasetID
WHERE (P.State_ID IN (2, 5))


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Helper_List_Report] TO [DDL_Viewer] AS [dbo]
GO
