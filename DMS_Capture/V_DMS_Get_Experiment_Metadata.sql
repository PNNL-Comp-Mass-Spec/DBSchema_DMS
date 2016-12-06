/****** Object:  View [dbo].[V_DMS_Get_Experiment_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_DMS_Get_Experiment_Metadata
AS
SELECT T.Experiment_Num,
       AI.Target,
       AI.Category,
       AI.Subcategory,
       AI.Item,
       AI.Value
FROM S_DMS_T_Experiments AS T
     INNER JOIN S_DMS_V_AuxInfo_Value AS AI
       ON T.Exp_ID = AI.Target_ID
WHERE (AI.Target = 'Experiment')

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Get_Experiment_Metadata] TO [DDL_Viewer] AS [dbo]
GO
