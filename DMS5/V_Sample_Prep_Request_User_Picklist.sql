/****** Object:  View [dbo].[V_Sample_Prep_Request_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Sample_Prep_Request_User_Picklist]
AS
SELECT     dbo.T_Users.U_Name AS val, dbo.T_Users.U_Name + ' (' + dbo.T_Users.U_PRN + ')' AS ex
FROM         dbo.T_Users INNER JOIN
                      dbo.T_User_Operations_Permissions ON dbo.T_Users.ID = dbo.T_User_Operations_Permissions.U_ID INNER JOIN
                      dbo.T_User_Operations ON dbo.T_User_Operations_Permissions.Op_ID = dbo.T_User_Operations.ID
WHERE     (dbo.T_Users.U_Status = 'Active') AND (dbo.T_User_Operations.Operation = 'DMS_Sample_Preparation')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_User_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_User_Picklist] TO [PNL\D3M580] AS [dbo]
GO
