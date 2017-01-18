/****** Object:  View [dbo].[V_Users_NWFs_Samba] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Users_NWFs_Samba]
AS
SELECT U_PRN AS [Payroll Num],
       U_Name AS Name
FROM dbo.T_Users
WHERE (U_active = 'Y') AND
      (U_PRN NOT IN ('svc-dms')) -- Exclude this user to prevent it from being mapped to the dmsarch-ro2 group by a nightly cron job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Users_NWFs_Samba] TO [DDL_Viewer] AS [dbo]
GO
