/****** Object:  View [dbo].[V_Settings_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Settings_File_Picklist]
AS
SELECT SF.File_Name,
       SF.Description,
       ISNULL(SettingsUsageQ.JobCount, 0) AS "Job Count",
       SF.Analysis_Tool
FROM dbo.T_Settings_Files SF
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON SF.Analysis_Tool = AnTool.AJT_toolName
     LEFT OUTER JOIN ( SELECT AJ_analysisToolID,
                              AJ_SettingsFileName,
                              COUNT(*) AS JobCount
                       FROM dbo.T_Analysis_Job
                       WHERE AJ_Created >= DateAdd(year, -2, GetDate())
                       GROUP BY AJ_SettingsFileName, AJ_analysisToolID ) SettingsUsageQ
       ON AnTool.AJT_toolID = SettingsUsageQ.AJ_analysisToolID AND
          SF.File_Name = SettingsUsageQ.AJ_SettingsFileName
WHERE (SF.Active <> 0)

GO
