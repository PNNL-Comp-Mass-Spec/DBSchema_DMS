/****** Object:  View [dbo].[V_Experiment_Groups_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Groups_Detail_Report]
AS
SELECT EG.Group_ID AS id,
       EG.EG_Group_Type AS group_type,
       EG.group_name,
       E.Experiment_Num AS parent_experiment,
       COUNT(EGM.Exp_ID) AS members,
       EG.EG_Description AS description,
       EG.EG_Created AS created,
       EG.Prep_LC_Run_ID AS prep_lc_run,
       CASE WHEN EG.Researcher IS NULL THEN ''
            ELSE U.name_with_prn
       END AS researcher,
       COUNT(DISTINCT DS.Dataset_ID) AS datasets,
       ISNULL(FA.filecount, 0) AS experiment_group_files
FROM dbo.T_Experiment_Groups AS EG
     LEFT OUTER JOIN dbo.T_Experiment_Group_Members AS EGM
       ON EG.Group_ID = EGM.Group_ID
     INNER JOIN dbo.T_Experiments AS E
       ON EG.Parent_Exp_ID = E.Exp_ID
     LEFT OUTER JOIN dbo.T_Dataset DS
       ON EGM.Exp_ID = DS.Exp_ID
     LEFT OUTER JOIN dbo.T_Users AS U
       ON EG.Researcher = U.U_PRN
     LEFT OUTER JOIN ( SELECT Entity_ID,
                              COUNT(*) AS FileCount
                       FROM dbo.T_File_Attachment
                       WHERE (Entity_Type = 'experiment_group') AND
                             Active > 0
                       GROUP BY Entity_ID
					 ) AS FA
       ON EG.Group_ID = CONVERT(int, FA.Entity_ID)
GROUP BY EG.Group_ID, EG.EG_Group_Type, EG.Group_Name, EG.EG_Description,
         EG.EG_Created, E.Experiment_Num, EG.Prep_LC_Run_ID, FA.FileCount,
		 CASE WHEN EG.Researcher IS NULL THEN ''
              ELSE U.Name_with_PRN
         END


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
