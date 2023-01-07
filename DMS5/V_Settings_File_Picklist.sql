/****** Object:  View [dbo].[V_Settings_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Settings_File_Picklist]
AS
SELECT file_name,
       description,
       job_count,
       jobs_all_time,
       analysis_tool,
       CASE WHEN Job_Count > 0 THEN Job_Count + 1000000 ELSE Jobs_all_time END AS sort_key
FROM (
    SELECT SF.File_Name,
           SF.Description,
           ISNULL(SF.Job_Usage_Last_Year, 0) AS Job_Count,
           ISNULL(SF.Job_Usage_Count, 0) AS Jobs_all_time,
           SF.Analysis_Tool
    FROM dbo.T_Settings_Files SF
         INNER JOIN dbo.T_Analysis_Tool AnTool
           ON SF.Analysis_Tool = AnTool.AJT_toolName
    WHERE (SF.Active <> 0)
    UNION
    SELECT SF.File_Name,
           SF.Description,
           ISNULL(SF.Job_Usage_Last_Year, 0) AS Job_Count,
           ISNULL(SF.Job_Usage_Count, 0) AS Jobs_all_time,
           AnTool.AJT_toolName AS Analysis_Tool
    FROM T_Settings_Files SF
         INNER JOIN T_Analysis_Tool AnTool
           ON SF.Analysis_Tool = AnTool.AJT_toolBasename
    WHERE (SF.Active <> 0)
) FilterQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_File_Picklist] TO [DDL_Viewer] AS [dbo]
GO
