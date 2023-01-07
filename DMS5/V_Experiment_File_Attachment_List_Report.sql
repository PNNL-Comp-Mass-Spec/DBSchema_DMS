/****** Object:  View [dbo].[V_Experiment_File_Attachment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_File_Attachment_List_Report]
AS
SELECT E.exp_id,
       FA.id,
       FA.file_name,
       ISNULL(FA.description, '') AS description,
       FA.entity_type,
       FA.entity_id,
       FA.owner,
       FA.size_kb,
       FA.created,
       FA.last_affected,
       E.Experiment_Num As experiment
FROM V_File_Attachment_List_Report FA
     INNER JOIN dbo.T_Experiments E
       ON FA.Entity_ID = E.Experiment_Num
WHERE Entity_Type = 'experiment'
UNION
SELECT EGM.Exp_ID,
       LookupQ.ID,
       LookupQ.File_Name,
       LookupQ.Description,
       LookupQ.Entity_Type,
       LookupQ.Entity_ID,
       LookupQ.Owner,
       LookupQ.Size_KB,
       LookupQ.Created,
       LookupQ.Last_Affected,
       E.Experiment_Num As Experiment
FROM ( SELECT ID,
              File_Name,
              Description,
              Entity_Type,
              Entity_ID,
              Owner,
              Size_KB,
              Created,
              Last_Affected
       FROM V_File_Attachment_List_Report
       WHERE Entity_Type = 'experiment_group'
     ) LookupQ
     INNER JOIN T_Experiment_Group_Members EGM
       ON CONVERT(int, LookupQ.Entity_ID) = EGM.Group_ID
     INNER JOIN dbo.T_Experiments E
       ON EGM.Exp_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_File_Attachment_List_Report] TO [DDL_Viewer] AS [dbo]
GO
