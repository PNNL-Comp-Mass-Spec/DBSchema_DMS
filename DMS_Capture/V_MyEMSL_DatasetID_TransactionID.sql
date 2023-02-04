/****** Object:  View [dbo].[V_MyEMSL_DatasetID_TransactionID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_DatasetID_TransactionID]
AS
SELECT Dataset_ID,
       -- TransactionID was deprecated 2019-05-21; use StatusNum (aka MyEMSL Upload ID) if null
       Coalesce(TransactionID, StatusNum) As Transaction_ID,
       Verified,
       FileCountNew AS File_Count_New,
       FileCountUpdated AS File_Count_Updated
FROM dbo.T_MyEMSL_Uploads
WHERE Not StatusNum Is Null Or 
      Not TransactionID Is Null

GO
