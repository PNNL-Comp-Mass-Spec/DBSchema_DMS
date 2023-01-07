/****** Object:  View [dbo].[V_Param_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Picklist]
AS
SELECT PF.Param_File_Name AS name,
       PF.Param_File_Description AS description,
	   ISNULL(PF.job_usage_last_year, 0) AS job_count,
       ISNULL(PF.job_usage_count, 0) AS jobs_all_time,
       PF.Param_File_ID AS id,
       AnTool.AJT_toolName AS tool_name,
	   CASE WHEN ISNULL(PF.job_usage_last_year, 0) > 0 THEN PF.Job_Usage_Last_Year + 1000000 ELSE ISNULL(PF.job_usage_count, 0) END AS sort_key
FROM dbo.T_Param_Files PF
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
WHERE (PF.Valid = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Picklist] TO [DDL_Viewer] AS [dbo]
GO
