/****** Object:  View [dbo].[V_GetPipelineSettingsFilesAsText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GetPipelineSettingsFilesAsText]
AS
SELECT ID,
       Analysis_Tool,
       File_Name,
       Description,
       Active,
       Last_Updated,
       CONVERT(varchar(MAX), Contents) AS Contents,
       Job_Usage_Count
FROM dbo.T_Settings_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineSettingsFilesAsText] TO [DDL_Viewer] AS [dbo]
GO
