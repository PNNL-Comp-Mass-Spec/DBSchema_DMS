/****** Object:  View [dbo].[V_Analysis_Tool_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_Tool_Paths
AS
SELECT AJT_toolName AS ToolName, 
   AJT_parmFileStoragePathLocal AS ParamDir, 
   AJT_parmFileStoragePathLocal + 'SettingsFiles\' AS SettingsDir
FROM dbo.T_Analysis_Tool
WHERE (AJT_toolID > 0)
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Paths] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Paths] TO [PNL\D3M580] AS [dbo]
GO
