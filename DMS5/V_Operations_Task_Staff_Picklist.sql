/****** Object:  View [dbo].[V_Operations_Task_Staff_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Task_Staff_Picklist] as
SELECT U.U_PRN AS PRN,
       U.Name_with_PRN AS Name
FROM T_User_Operations_Permissions O
     INNER JOIN T_Users U
       ON O.U_ID = U.ID
WHERE U.U_Status = 'Active' AND
      O.Op_ID IN (16)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Task_Staff_Picklist] TO [DDL_Viewer] AS [dbo]
GO
