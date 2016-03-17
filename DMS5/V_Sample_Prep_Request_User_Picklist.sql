/****** Object:  View [dbo].[V_Sample_Prep_Request_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_User_Picklist]
AS
SELECT U.U_Name AS val,
       U.Name_with_PRN AS ex
FROM dbo.T_Users U
     INNER JOIN dbo.T_User_Operations_Permissions UOP
       ON U.ID = UOP.U_ID
     INNER JOIN dbo.T_User_Operations UO
       ON UOP.Op_ID = UO.ID
WHERE (U.U_Status = 'Active') AND
      (UO.Operation = 'DMS_Sample_Preparation')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_User_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_User_Picklist] TO [PNL\D3M580] AS [dbo]
GO
