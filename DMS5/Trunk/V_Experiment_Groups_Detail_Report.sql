/****** Object:  View [dbo].[V_Experiment_Groups_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Groups_Detail_Report]
AS
SELECT EG.Group_ID AS ID,
       EG.EG_Group_Type AS Group_Type,
       EG.Tab,
       E.Experiment_Num AS Parent_Experiment,
       COUNT(EGM.Exp_ID) AS Members,
       EG.EG_Description AS Description,
       EG.EG_Created AS Created,
       EG.Prep_LC_Run_ID AS [Prep LC Run],
       CASE
           WHEN EG.Researcher IS NULL THEN ''
           ELSE U.U_Name + ' (' + U.U_PRN + ')'
       END AS Researcher,
       ISNULL(FA.FileCount, 0) AS [Experiment Group Files]
FROM dbo.T_Experiment_Groups EG
     LEFT OUTER JOIN dbo.T_Experiment_Group_Members EGM
       ON EG.Group_ID = EGM.Group_ID
     INNER JOIN dbo.T_Experiments E
       ON EG.Parent_Exp_ID = E.Exp_ID
     LEFT OUTER JOIN dbo.T_Users U
       ON EG.Researcher = U.U_PRN
     LEFT OUTER JOIN ( SELECT Entity_ID,
                              COUNT(*) AS FileCount
                       FROM T_File_Attachment
                       WHERE (Entity_Type = 'experiment_group')
                       GROUP BY Entity_ID 
                     ) FA
       ON EG.Group_ID = CONVERT(int, FA.Entity_ID)
GROUP BY EG.Group_ID, EG.EG_Group_Type, EG.Tab, EG.EG_Description, 
         EG.EG_Created, E.Experiment_Num, EG.Prep_LC_Run_ID, 
         CASE WHEN EG.Researcher IS NULL 
              THEN ''
              ELSE U.U_Name + ' (' + U.U_PRN + ')' 
              END, 
         FA.FileCount

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
