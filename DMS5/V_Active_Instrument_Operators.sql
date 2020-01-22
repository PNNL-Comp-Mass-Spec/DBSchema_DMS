/****** Object:  View [dbo].[V_Active_Instrument_Operators] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Instrument_Operators]
As
SELECT DISTINCT U.U_PRN AS [Payroll Num],
                U.U_Name AS [Name]
FROM T_Users AS U
     INNER JOIN T_User_Operations_Permissions AS Ops_Permissions
       ON U.ID = Ops_Permissions.U_ID
     INNER JOIN T_User_Operations AS Ops
       ON Ops_Permissions.Op_ID = Ops.ID
WHERE U.U_Status = 'Active' AND
      Ops.Operation IN ('DMS_Instrument_Operation', 'DMS_Infrastructure_Administration')


GO
