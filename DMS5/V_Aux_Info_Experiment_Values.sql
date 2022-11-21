/****** Object:  View [dbo].[V_Aux_Info_Experiment_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Experiment_Values]
AS
SELECT T_Experiments.Experiment_Num AS Experiment,
       T_Experiments.Exp_ID AS ID,
       T_Aux_Info_Category.Aux_Category AS Category,
       T_Aux_Info_Subcategory.Aux_Subcategory AS Subcategory,
       T_Aux_Info_Description.Aux_Description AS Item,
       T_Aux_Info_Value.Value
FROM T_Aux_Info_Category
     INNER JOIN T_Aux_Info_Subcategory
       ON T_Aux_Info_Category.Aux_Category_ID = T_Aux_Info_Subcategory.Aux_Category_ID
     INNER JOIN T_Aux_Info_Description
       ON T_Aux_Info_Subcategory.Aux_Subcategory_ID = T_Aux_Info_Description.Aux_Subcategory_ID
     INNER JOIN T_Aux_Info_Value
       ON T_Aux_Info_Description.Aux_Description_ID = T_Aux_Info_Value.Aux_Description_ID
     INNER JOIN T_Experiments
       ON T_Aux_Info_Value.Target_ID = T_Experiments.Exp_ID
WHERE T_Aux_Info_Category.Target_Type_ID = 500


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Experiment_Values] TO [DDL_Viewer] AS [dbo]
GO
