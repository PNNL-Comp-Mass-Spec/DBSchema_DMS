/****** Object:  View [dbo].[V_Experiment_Groups_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Groups_List_Report] 
AS 
SELECT EG.Group_ID AS ID,
       EG.EG_Group_Type AS Group_Type,
       EG.Group_Name,
       EG.EG_Description AS Description,
       EG.MemberCount Members,
       TA.Attachments AS Files,
       E.Experiment_Num AS Parent_Experiment,
       EG.EG_Created AS Created,
       CASE
           WHEN EG.Researcher IS NULL THEN ''
           ELSE T_Users.Name_with_PRN
       END AS Researcher
FROM dbo.T_Experiment_Groups As EG    
     INNER JOIN dbo.T_Experiments As E
       ON EG.Parent_Exp_ID = E.Exp_ID
     LEFT OUTER JOIN ( SELECT Entity_ID AS [Entity ID],
                              COUNT(*) AS Attachments
                       FROM dbo.T_File_Attachment
                       WHERE (Entity_Type = 'experiment_group') AND
                             Active > 0
                       GROUP BY Entity_ID 
					 ) AS TA
       ON EG.Group_ID = TA.[Entity ID]
     LEFT OUTER JOIN dbo.T_Users
       ON EG.Researcher = dbo.T_Users.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Groups_List_Report] TO [DDL_Viewer] AS [dbo]
GO
