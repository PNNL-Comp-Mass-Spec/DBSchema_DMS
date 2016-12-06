/****** Object:  View [dbo].[V_Experiment_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_File_Attachment_List_Report] AS 
SELECT E.Exp_ID,
       FA.ID,
       FA.[File Name],
       ISNULL(FA.Description, '') AS Description,
       FA.[Entity Type],
       FA.[Entity ID],
       FA.Owner,
       FA.[Size (KB)],
       FA.Created,
       FA.[Last Affected],
       E.Experiment_Num As Experiment
FROM V_File_Attachment_List_Report FA
     INNER JOIN dbo.T_Experiments E
       ON FA.[Entity ID] = E.Experiment_Num
WHERE [Entity Type] = 'experiment'
UNION
SELECT EGM.Exp_ID,
       LookupQ.ID,
       LookupQ.[File Name],
       LookupQ.Description,
       LookupQ.[Entity Type],
       LookupQ.[Entity ID],
       LookupQ.Owner,
       LookupQ.[Size (KB)],
       LookupQ.Created,
       LookupQ.[Last Affected],
       E.Experiment_Num As Experiment
FROM ( SELECT ID,
              [File Name],
              Description,
              [Entity Type],
              [Entity ID],
              Owner,
              [Size (KB)],
              Created,
              [Last Affected]
       FROM [V_File_Attachment_List_Report]
       WHERE [Entity Type] = 'experiment_group' 
     ) LookupQ
     INNER JOIN T_Experiment_Group_Members EGM
       ON CONVERT(int, LookupQ.[Entity ID]) = EGM.Group_ID
     INNER JOIN dbo.T_Experiments E
       ON EGM.Exp_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_File_Attachment_List_Report] TO [DDL_Viewer] AS [dbo]
GO
