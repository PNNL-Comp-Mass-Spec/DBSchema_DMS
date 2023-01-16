/****** Object:  View [dbo].[V_Dataset_Comments_Recent_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Comments_Recent_Datasets]
AS
SELECT Dataset_ID, 
       DS.Dataset_Num AS Dataset, 
       DS_comment As Comment, 
       DS_state_ID As State_ID, 
       DSN.DSS_name AS State,
       DS_created As Created,
       DateDiff(Week, DS.DS_created, GetDate()) As Age_Weeks
FROM T_Dataset DS
     INNER JOIN T_DatasetStateName DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
WHERE DS_created >= DATEADD(month, -12, GETDATE())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Comments_Recent_Datasets] TO [DDL_Viewer] AS [dbo]
GO
