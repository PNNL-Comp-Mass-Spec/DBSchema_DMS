/****** Object:  View [dbo].[V_Datasets_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Datasets_RSS]
AS
SELECT Dataset AS url_title,
       CONVERT(varchar(12), ID) + ' - ' + Dataset AS post_title,
       CONVERT(varchar(12), ID) AS guid,
       ' Dataset:' + Dataset + '| Experiment:' + Experiment + '| Researcher:' + Researcher + 
       '| Experiment Group:' + Exp_Group + ', Experiment Group ID:' + CONVERT(varchar(12), Group_ID) 
         AS post_body,
       Researcher AS U_PRN,
       Created AS post_date
FROM ( SELECT DS.Dataset_ID AS ID,
              DS.Dataset_Num AS Dataset,
              E.Experiment_Num AS Experiment,
              E.EX_researcher_PRN AS Researcher,
              dbo.T_Experiment_Groups.EG_Description AS Exp_Group,
              dbo.T_Experiment_Groups.Group_ID,
              DS.DS_created AS Created
       FROM dbo.T_Dataset AS DS
            INNER JOIN dbo.T_Experiments AS E
              ON DS.Exp_ID = E.Exp_ID
            INNER JOIN dbo.T_Experiment_Group_Members
              ON E.Exp_ID = dbo.T_Experiment_Group_Members.Exp_ID
            INNER JOIN dbo.T_Experiment_Groups
              ON dbo.T_Experiment_Group_Members.Group_ID = dbo.T_Experiment_Groups.Group_ID
       WHERE (DS.DS_created > DATEADD(day, -30, GETDATE())) ) AS FilterQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_RSS] TO [DDL_Viewer] AS [dbo]
GO
