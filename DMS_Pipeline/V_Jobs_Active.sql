/****** Object:  View [dbo].[V_Jobs_Active] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Jobs_Active] 
AS
SELECT J.Job,
       J.Priority,
       J.Script,
       J.Job_State_B AS Job_State,
       J.Dataset,
       J.Imported,
       J.Start,
       J.Finish,
       IsNull(AJPGA.Group_Name, '') AS Processor_Group,
       D.AJ_ParmFileName AS Parameter_File_Name,
       D.AJ_SettingsFileName AS Settings_File_Name,
       J.Results_Folder_Name,
       J.Transfer_Folder_Path,
       Row_Number() OVER ( ORDER BY CASE WHEN J.Job_State_B = 'Failed' THEN 'a' ELSE J.Job_State_B END DESC, J.Job ) AS SortOrder
FROM V_Pipeline_Jobs_List_Report J
     LEFT OUTER JOIN V_DMS_Analysis_Job_Processor_Group_Association_Recent AJPGA
       ON J.Job = AJPGA.Job
     LEFT OUTER JOIN dbo.S_DMS_T_Analysis_Job D
       ON J.Job = D.AJ_JobID
WHERE J.Job_State_B NOT IN ('complete', 'failed') AND J.Imported >= DateAdd(day, -120, GetDate()) OR
      J.Job_State_B <> 'complete' AND J.Imported >= DateAdd(day, -31, GetDate()) OR
      J.Imported >= DateAdd(day, -1, GetDate()) OR
      J.Finish >= DateAdd(day, -1, GetDate())
UNION
SELECT D.Job,
       D.Priority,
       D.Tool,
       CASE
           WHEN D.State = 1 THEN 'New'
           WHEN D.State = 8 THEN 'Holding'
           ELSE '??'
       END + ' (not in Pipeline DB)' AS State,
       D.Dataset,
       NULL AS Imported,
       NULL AS Start,
       NULL AS Finish,
       '' AS Processor_Group,
       D.Parameter_File_Name,
       D.Settings_File_Name,
       '' AS Results_Folder_Name,
       D.Transfer_Folder_Path,
       0 AS SortOrder
FROM V_DMS_PipelineJobs D
     LEFT OUTER JOIN T_Jobs J
       ON D.Job = J.Job
WHERE D.State IN (1, 8) AND
      J.Job IS NULL


GO
GRANT VIEW DEFINITION ON [dbo].[V_Jobs_Active] TO [PNL\D3M578] AS [dbo]
GO
