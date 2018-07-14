/****** Object:  View [dbo].[V_MyEMSL_Proposal_ID_Update] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Proposal_ID_Update] 
AS 
-- This view is used by MyEMSL to check for updated EUS Proposal IDs
SELECT RR.ID AS Request_ID,
       DS.Dataset_ID AS Dataset_ID,
       dbo.GetDatasetMyEMSLTransactionIDs(DS.Dataset_ID) AS [MyEMSL_Transaction_ID_list],
       RR.RDS_EUS_Proposal_ID,
       RR.Updated AS Updated
FROM T_Requested_Run AS RR
     INNER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID

GO
