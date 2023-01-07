/****** Object:  View [dbo].[V_Operations_User_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_User_List_Report]
As
-- Note that GetOperationDMSUsersNameList only includes Active users
SELECT operation,
       operation_description,
       dbo.GetOperationDMSUsersNameList(ID, 0) AS assigned_users
FROM dbo.T_User_Operations


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_User_List_Report] TO [DDL_Viewer] AS [dbo]
GO
