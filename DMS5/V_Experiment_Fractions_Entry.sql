/****** Object:  View [dbo].[V_Experiment_Fractions_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Experiment_Fractions_Entry
AS
SELECT EG.Group_ID AS id,
       EG.EG_Group_Type AS group_type,
       E.Experiment_Num AS parent_experiment,
       EG.EG_Description AS description,
       EG.EG_Created AS created,
       1 AS starting_index,
       1 AS step,
       25 AS total_count
FROM T_Experiment_Groups EG
     INNER JOIN T_Experiments E
       ON EG.Parent_Exp_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Fractions_Entry] TO [DDL_Viewer] AS [dbo]
GO
