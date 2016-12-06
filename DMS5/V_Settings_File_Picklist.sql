/****** Object:  View [dbo].[V_Settings_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Settings_File_Picklist]
AS
SELECT File_Name,
       Description,
       [Job Count],
       [Jobs (all time)],
       Analysis_Tool,
       CASE WHEN [Job Count] > 0 THEN [Job Count] + 1000000 ELSE [Jobs (all time)] END as SortKey
FROM (
    SELECT SF.File_Name,
           SF.Description,
           ISNULL(SF.Job_Usage_Last_Year, 0) AS [Job Count],
           ISNULL(SF.Job_Usage_Count, 0) AS [Jobs (all time)],
           SF.Analysis_Tool,
           CASE WHEN ISNULL(SF.Job_Usage_Last_Year, 0) > 0 THEN SF.Job_Usage_Last_Year ELSE ISNULL(SF.Job_Usage_Count, 0) - 100000000 END as SortKey
    FROM dbo.T_Settings_Files SF
         INNER JOIN dbo.T_Analysis_Tool AnTool
           ON SF.Analysis_Tool = AnTool.AJT_toolName
    WHERE (SF.Active <> 0)
    UNION
    SELECT SF.File_Name,
           SF.Description,
           ISNULL(SF.Job_Usage_Last_Year, 0) AS [Job Count],
           ISNULL(SF.Job_Usage_Count, 0) AS [Jobs (all time)],
           AnTool.AJT_toolName AS Analysis_Tool,
           CASE WHEN ISNULL(SF.Job_Usage_Last_Year, 0) > 0 THEN SF.Job_Usage_Last_Year ELSE ISNULL(SF.Job_Usage_Count, 0) - 100000000 END as SortKey
    FROM T_Settings_Files SF
         INNER JOIN T_Analysis_Tool AnTool
           ON SF.Analysis_Tool = AnTool.AJT_toolBasename
    WHERE (SF.Active <> 0)
) FilterQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_File_Picklist] TO [DDL_Viewer] AS [dbo]
GO
