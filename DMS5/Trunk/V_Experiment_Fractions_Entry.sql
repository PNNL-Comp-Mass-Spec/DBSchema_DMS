/****** Object:  View [dbo].[V_Experiment_Fractions_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Experiment_Fractions_Entry
AS
SELECT     T_Experiment_Groups.Group_ID AS ID, T_Experiment_Groups.EG_Group_Type AS Group_Type, 
                      T_Experiments.Experiment_Num AS Parent_Experiment, T_Experiment_Groups.EG_Description AS Description, 
                      T_Experiment_Groups.EG_Created AS Created, 1 AS Starting_Index, 1 AS Step, 25 AS Total_Count
FROM         T_Experiment_Groups INNER JOIN
                      T_Experiments ON T_Experiment_Groups.Parent_Exp_ID = T_Experiments.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Fractions_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Fractions_Entry] TO [PNL\D3M580] AS [dbo]
GO
