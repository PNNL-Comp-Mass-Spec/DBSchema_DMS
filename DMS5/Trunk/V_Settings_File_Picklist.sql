/****** Object:  View [dbo].[V_Settings_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Settings_File_Picklist]
AS
SELECT SF.File_Name,
       SF.Description,
       ISNULL(SF.Job_Usage_Count, 0) AS "Job Count",
       SF.Analysis_Tool
FROM dbo.T_Settings_Files SF
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON SF.Analysis_Tool = AnTool.AJT_toolName
WHERE (SF.Active <> 0)

GO
