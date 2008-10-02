/****** Object:  View [dbo].[V_Experiment_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_User_Picklist
AS
SELECT DISTINCT dbo.T_Users.U_PRN AS [Payroll Num], dbo.T_Users.U_Name AS Name
FROM         dbo.T_Users INNER JOIN
                      dbo.T_Experiments ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN
WHERE     (DATEDIFF(Month, dbo.T_Experiments.EX_created, GETDATE()) <= 12) AND (dbo.T_Users.U_Status = 'Active')

GO
