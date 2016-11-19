/****** Object:  View [dbo].[V_Operations_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_User_Detail_Report]
AS
SELECT Operation,
       Operation_Description AS Description,
       dbo.GetOperationDMSUsersNameList(ID, 1) AS [Assigned Users]
FROM dbo.T_User_Operations


GO
