/****** Object:  View [dbo].[V_Experiment_Count_by_User] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Count_by_User
AS
SELECT dbo.T_Users.U_Name AS [User], COUNT(*) AS Total
FROM dbo.T_Experiments INNER JOIN
   dbo.T_Users ON 
   dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN
GROUP BY dbo.T_Users.U_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Count_by_User] TO [PNL\D3M578] AS [dbo]
GO
