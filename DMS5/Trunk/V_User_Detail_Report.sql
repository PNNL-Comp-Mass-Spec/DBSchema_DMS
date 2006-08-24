/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_User_Detail_Report
AS
SELECT     U_PRN AS [Payroll Num], U_HID AS HID, U_Name AS Name, U_Access_Lists AS Access, U_email AS Email
FROM         dbo.T_Users

GO
