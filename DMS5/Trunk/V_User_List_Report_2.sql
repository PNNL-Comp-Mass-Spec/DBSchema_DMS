/****** Object:  View [dbo].[V_User_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_User_List_Report_2
AS
SELECT     U_PRN AS [Payroll Num], U_Name AS Name, U_Status AS Status, dbo.GetUserOperationsList(ID) AS [Operations List], ID
FROM         dbo.T_Users AS U
GROUP BY U_PRN, U_HID, U_Name, U_email, U_Status, ID

GO
