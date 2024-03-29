/****** Object:  View [dbo].[V_Biomaterial_Experiment_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Experiment_Tracking]
AS
SELECT T_Experiments.Experiment_Num AS experiment,
       COUNT(T_Dataset.Dataset_ID) AS datasets,
       T_Experiments.EX_reason AS reason,
       T_Experiments.EX_created AS created,
       T_Cell_Culture.CC_Name AS biomaterial_name
FROM T_Experiment_Cell_Cultures
     INNER JOIN T_Experiments
       ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
     INNER JOIN T_Cell_Culture
       ON T_Experiment_Cell_Cultures.CC_ID = T_Cell_Culture.CC_ID
     LEFT OUTER JOIN T_Dataset
       ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
GROUP BY T_Cell_Culture.CC_Name, T_Experiments.Experiment_Num,
         T_Experiments.EX_reason, T_Experiments.EX_created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Experiment_Tracking] TO [DDL_Viewer] AS [dbo]
GO
