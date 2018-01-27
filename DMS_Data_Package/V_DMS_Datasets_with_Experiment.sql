/****** Object:  View [dbo].[V_DMS_Datasets_with_Experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Datasets_with_Experiment]
AS
SELECT S_Dataset.Dataset_ID,
       S_Dataset.Dataset_Num As Dataset,
       S_Dataset.Exp_ID,
       Experiment_Num As Experiment
FROM S_Dataset
     INNER JOIN S_experiment_list
       ON S_Dataset.Exp_ID = S_experiment_list.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Datasets_with_Experiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_DMS_Datasets_with_Experiment] TO [DMS_SP_User] AS [dbo]
GO
