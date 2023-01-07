/****** Object:  View [dbo].[V_Experiment_Stats_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Stats_List_Report
AS
SELECT year, month, experiments, researcher
FROM (SELECT DATEPART(month, EX_created) AS Month, DATEPART(year, EX_created) AS Year, COUNT(*) AS Experiments, 'Total' AS Researcher
      FROM T_Experiments
      GROUP BY DATEPART(month, EX_created), DATEPART(year, EX_created)
      UNION
      SELECT DATEPART(month, T_Experiments.EX_created) AS Month, DATEPART(year, T_Experiments.EX_created) AS Year, COUNT(*) AS Experiments,
                            T_Users.U_Name AS Researcher
      FROM T_Experiments INNER JOIN
                            T_Users ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN
      GROUP BY DATEPART(month, T_Experiments.EX_created), DATEPART(year, T_Experiments.EX_created), T_Users.U_Name
     ) T


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Stats_List_Report] TO [DDL_Viewer] AS [dbo]
GO
