/****** Object:  View [dbo].[V_Experiment_Cell_Culture_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Cell_Culture_Report]
AS
SELECT E.Experiment_Num AS Experiment,
       E.EX_researcher_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_comment AS [Comment],
       CC.CC_Name AS cell_culture
FROM T_Experiment_Cell_Cultures ECC
     INNER JOIN T_Experiments E
       ON ECC.Exp_ID = E.Exp_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Cell_Culture CC
       ON ECC.CC_ID = CC.CC_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Cell_Culture_Report] TO [DDL_Viewer] AS [dbo]
GO
