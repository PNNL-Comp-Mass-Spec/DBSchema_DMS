/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_User_Detail_Report
AS
SELECT     U_PRN AS PRN, U_HID AS HID, U_Name AS Name, U_email AS Email, U_Status AS Status, dbo.GetUserOperationsList(ID) AS [Operations List]
FROM         dbo.T_Users

GO
