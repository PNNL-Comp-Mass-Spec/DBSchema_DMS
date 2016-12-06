/****** Object:  View [dbo].[V_Experiment_Groups_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Groups_Entry
AS
SELECT        dbo.T_Experiment_Groups.Group_ID AS ID, dbo.T_Experiment_Groups.EG_Group_Type AS GroupType, dbo.T_Experiment_Groups.Tab, 
                         dbo.T_Experiment_Groups.EG_Description AS Description, dbo.T_Experiments.Experiment_Num AS ParentExp, 
                         dbo.GetExpGroupExperimentList(dbo.T_Experiment_Groups.Group_ID) AS ExperimentList, dbo.T_Experiment_Groups.Researcher
FROM            dbo.T_Experiment_Groups INNER JOIN
                         dbo.T_Experiments ON dbo.T_Experiment_Groups.Parent_Exp_ID = dbo.T_Experiments.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_Entry] TO [DDL_Viewer] AS [dbo]
GO
