/****** Object:  View [dbo].[V_Charge_Code_Owner_DMS_User_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Charge_Code_Owner_DMS_User_Map]
AS
SELECT CC.Charge_Code,
       U.U_PRN AS Username,
       U.U_Name AS Name,
       U.U_Payroll AS Payroll
FROM T_Charge_Code CC
     INNER JOIN T_Users U
       ON 'H' + CC.Resp_HID = U.U_HID
WHERE U.U_Status <> 'Obsolete'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Charge_Code_Owner_DMS_User_Map] TO [DDL_Viewer] AS [dbo]
GO
