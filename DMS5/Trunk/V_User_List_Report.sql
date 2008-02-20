/****** Object:  View [dbo].[V_User_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_User_List_Report
AS
SELECT U_PRN AS [Payroll Num], U_HID AS HID, U_Name AS Name, 
       count(U_ID) as Operations, U_email AS Email, U_Status AS Status
FROM    dbo.T_Users U
       LEFT JOIN T_User_Operations_Permissions O on O.U_ID = U.ID
GROUP BY U_PRN, U_HID, U_Name, U_email, U_Status


GO
