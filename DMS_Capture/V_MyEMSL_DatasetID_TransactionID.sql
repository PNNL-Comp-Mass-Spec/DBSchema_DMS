/****** Object:  View [dbo].[V_MyEMSL_DatasetID_TransactionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_DatasetID_TransactionID]
AS
SELECT Dataset_ID,
       TransactionID,
       Verified,
       FileCountNew,
       FileCountUpdated
FROM dbo.T_MyEMSL_Uploads
WHERE Not TransactionID Is Null

GO
