/****** Object:  View [dbo].[V_All_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_All_Users
AS
SELECT U_PRN AS [Payroll Num], U_HID AS HID, 
   U_Name AS Name, U_Access_Lists AS Access
FROM dbo.T_Users
GO
GRANT VIEW DEFINITION ON [dbo].[V_All_Users] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_All_Users] TO [PNL\D3M580] AS [dbo]
GO
