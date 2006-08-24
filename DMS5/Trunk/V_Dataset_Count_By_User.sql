/****** Object:  View [dbo].[V_Dataset_Count_By_User] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Dataset_Count_By_User
AS
SELECT T_Dataset.DS_Oper_PRN, COUNT(*) AS Total, 
   T_Users.U_Name
FROM T_Dataset INNER JOIN
   T_Users ON 
   T_Dataset.DS_Oper_PRN = T_Users.U_PRN
GROUP BY T_Dataset.DS_Oper_PRN, T_Users.U_Name
GO
