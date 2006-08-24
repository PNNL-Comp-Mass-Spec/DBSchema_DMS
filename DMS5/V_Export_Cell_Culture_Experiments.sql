/****** Object:  View [dbo].[V_Export_Cell_Culture_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

                       
create view V_Export_Cell_Culture_Experiments
as
SELECT     T_Cell_Culture.CC_Name AS CellCulture, T_Experiments.Experiment_Num AS Experiment
 FROM         T_Cell_Culture INNER JOIN
                       T_Experiment_Cell_Cultures ON T_Cell_Culture.CC_ID = T_Experiment_Cell_Cultures.CC_ID INNER JOIN
                       T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID

GO
