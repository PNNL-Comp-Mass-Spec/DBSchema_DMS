/****** Object:  View [dbo].[V_GetPipelineSettingsFiles] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetPipelineSettingsFiles]
AS
SELECT ID,
       Analysis_Tool,
       File_Name,
       Description,
       Active,
       Last_Updated,
       Contents,
       Job_Usage_Count
FROM dbo.T_Settings_Files


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineSettingsFiles] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineSettingsFiles] TO [PNL\D3M580] AS [dbo]
GO
