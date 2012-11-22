/****** Object:  View [dbo].[V_Operations_Task_Staff_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Operations_Task_Staff_Picklist as
SELECT  U.U_PRN AS PRN ,
        U.U_Name + ' (' + CAST(U.U_PRN AS VARCHAR(12)) + ')' AS Name
FROM    T_User_Operations_Permissions O
        INNER JOIN T_Users U ON O.U_ID = U.ID
WHERE   ( U.U_Status = 'Active' )
AND O.Op_ID IN (16)

	      

GO
