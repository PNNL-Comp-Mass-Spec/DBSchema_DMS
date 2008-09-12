/****** Object:  View [dbo].[V_Active_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Active_Users
AS
SELECT     U_PRN AS [Payroll Num], U_Name AS Name
FROM         dbo.T_Users
WHERE     (U_Status = 'Active')

GO
