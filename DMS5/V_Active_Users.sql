/****** Object:  View [dbo].[V_Active_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Users]
AS
SELECT U_PRN AS Username,
       U_Name AS Name,
       U_Name + ' (' + U_PRN + ')' As Name_with_Username
FROM dbo.T_Users
WHERE U_Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Active_Users] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Active_Users] TO [DMS_LCMSNet_User] AS [dbo]
GO
