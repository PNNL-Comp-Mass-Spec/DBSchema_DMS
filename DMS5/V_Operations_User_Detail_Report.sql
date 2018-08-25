/****** Object:  View [dbo].[V_Operations_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_User_Detail_Report]
As
-- Note that GetOperationDMSUsersNameList only includes Active users
SELECT Operation,
       Operation_Description AS Description,
       dbo.GetOperationDMSUsersNameList(ID, 1) AS [Assigned Users]
FROM dbo.T_User_Operations


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_User_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
