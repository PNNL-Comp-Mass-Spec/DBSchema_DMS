/****** Object:  View [dbo].[V_DMS_SettingsFiles] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_SettingsFiles
AS
SELECT ID,
       Analysis_Tool,
       File_Name,
       Description,
       Active,
       Last_Updated,
       Contents,
       Job_Usage_Count
FROM S_DMS_V_Get_Pipeline_Settings_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_SettingsFiles] TO [DDL_Viewer] AS [dbo]
GO
