/****** Object:  View [dbo].[V_Experiment_Groups_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Groups_Entry
AS
SELECT EG.Group_ID AS id,
       EG.EG_Group_Type AS group_type,
       EG.Tab As tab,
       EG.EG_Description AS description,
       E.Experiment_Num AS parent_exp,
       dbo.GetExpGroupExperimentList(EG.Group_ID) AS experiment_list,
       EG.researcher
FROM T_Experiment_Groups EG
     INNER JOIN T_Experiments E
       ON EG.Parent_Exp_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_Entry] TO [DDL_Viewer] AS [dbo]
GO
