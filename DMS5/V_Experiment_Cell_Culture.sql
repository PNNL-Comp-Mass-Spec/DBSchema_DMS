/****** Object:  View [dbo].[V_Experiment_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Cell_Culture
AS
SELECT dbo.T_Experiments.Experiment_Num, 
   dbo.T_Cell_Culture.CC_Name AS Cell_Culture_Name
FROM dbo.T_Experiment_Cell_Cultures INNER JOIN
   dbo.T_Experiments ON 
   dbo.T_Experiment_Cell_Cultures.Exp_ID = dbo.T_Experiments.Exp_ID
    INNER JOIN
   dbo.T_Cell_Culture ON 
   dbo.T_Experiment_Cell_Cultures.CC_ID = dbo.T_Cell_Culture.CC_ID
GO
