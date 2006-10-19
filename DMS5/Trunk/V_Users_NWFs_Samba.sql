/****** Object:  View [dbo].[V_Users_NWFs_Samba] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Users_NWFs_Samba
AS
SELECT     U_PRN AS [Payroll Num], U_Name AS Name
FROM         dbo.T_Users
WHERE     (U_active = 'Y')

GO
