/****** Object:  View [dbo].[V_Experiment_Groups_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Groups_List_Report] AS 
SELECT dbo.T_Experiment_Groups.Group_ID AS ID,
       dbo.T_Experiment_Groups.EG_Group_Type AS Group_Type,
       dbo.T_Experiment_Groups.Tab,
       dbo.T_Experiment_Groups.EG_Description AS Description,
       COUNT(dbo.T_Experiment_Group_Members.Exp_ID) AS Members,
       TA.Attachments AS Files,
       dbo.T_Experiments.Experiment_Num AS Parent_Experiment,
       dbo.T_Experiment_Groups.EG_Created AS Created,
       CASE
           WHEN T_Experiment_Groups.Researcher IS NULL THEN ''
           ELSE T_Users.Name_with_PRN
       END AS Researcher
FROM dbo.T_Experiment_Groups
     LEFT OUTER JOIN dbo.T_Experiment_Group_Members
       ON dbo.T_Experiment_Groups.Group_ID = dbo.T_Experiment_Group_Members.Group_ID
     INNER JOIN dbo.T_Experiments
       ON dbo.T_Experiment_Groups.Parent_Exp_ID = dbo.T_Experiments.Exp_ID
     LEFT OUTER JOIN ( SELECT Entity_ID AS [Entity ID],
                              COUNT(*) AS Attachments
                       FROM dbo.T_File_Attachment
                       WHERE (Entity_Type = 'experiment_group') AND
                             Active > 0
                       GROUP BY Entity_ID 
					 ) AS TA
       ON dbo.T_Experiment_Groups.Group_ID = TA.[Entity ID]
     LEFT OUTER JOIN dbo.T_Users
       ON dbo.T_Experiment_Groups.Researcher = dbo.T_Users.U_PRN
GROUP BY dbo.T_Experiment_Groups.Group_ID, dbo.T_Experiment_Groups.EG_Group_Type, 
         dbo.T_Experiment_Groups.EG_Description, dbo.T_Experiment_Groups.EG_Created, 
         dbo.T_Experiments.Experiment_Num, 
		 dbo.T_Experiment_Groups.Tab, TA.Attachments,
         CASE
            WHEN T_Experiment_Groups.Researcher IS NULL THEN ''
            ELSE T_Users.Name_with_PRN
         END


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_List_Report] TO [DDL_Viewer] AS [dbo]
GO
