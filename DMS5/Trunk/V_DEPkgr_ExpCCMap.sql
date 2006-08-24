/****** Object:  View [dbo].[V_DEPkgr_ExpCCMap] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_ExpCCMap
AS
SELECT     dbo.T_Experiment_Cell_Cultures.Exp_ID AS Experiment_ID, dbo.T_Experiment_Cell_Cultures.CC_ID AS Culture_ID, 
                      dbo.T_Experiments.Experiment_Num AS Experiment_Name, dbo.T_Cell_Culture.CC_Name AS Biomaterial_Source_Name
FROM         dbo.T_Experiment_Cell_Cultures INNER JOIN
                      dbo.T_Cell_Culture ON dbo.T_Experiment_Cell_Cultures.CC_ID = dbo.T_Cell_Culture.CC_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Experiment_Cell_Cultures.Exp_ID = dbo.T_Experiments.Exp_ID

GO
