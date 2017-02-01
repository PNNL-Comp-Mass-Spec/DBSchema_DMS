/****** Object:  View [dbo].[V_Experiment_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_User_Picklist]
AS
SELECT DISTINCT T_Users.U_PRN AS [Payroll Num],
                T_Users.U_Name AS [Name]
FROM T_Users
     INNER JOIN T_Experiments
       ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN
WHERE T_Experiments.EX_created > DateAdd(month, -12, GetDate()) AND
      T_Users.U_Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_User_Picklist] TO [DDL_Viewer] AS [dbo]
GO
