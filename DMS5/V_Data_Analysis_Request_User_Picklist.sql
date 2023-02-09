/****** Object:  View [dbo].[V_Data_Analysis_Request_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_User_Picklist]
AS
SELECT U.U_Name AS val,
       U.Name_with_PRN AS ex,
       U.U_PRN AS username
FROM dbo.T_Users U
     INNER JOIN dbo.T_User_Operations_Permissions UOP
       ON U.ID = UOP.U_ID
     INNER JOIN dbo.T_User_Operations UO
       ON UOP.Op_ID = UO.ID
WHERE (U.U_Status = 'Active') AND
      (UO.Operation = 'DMS_Data_Analysis_Request')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_User_Picklist] TO [DDL_Viewer] AS [dbo]
GO
