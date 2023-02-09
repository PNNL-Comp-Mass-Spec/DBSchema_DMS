/****** Object:  View [dbo].[V_Operations_Task_Staff] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Task_Staff] as
SELECT U.U_PRN AS Username,
       U.Name_with_PRN AS Name
FROM T_User_Operations_Permissions O
     INNER JOIN T_Users U
       ON O.U_ID = U.ID
WHERE U.U_Status = 'Active' AND
      O.Op_ID IN (16,       -- DMS_Sample_Preparation
                  36)       -- DMS_Sample_Prep_Request_State

GO
