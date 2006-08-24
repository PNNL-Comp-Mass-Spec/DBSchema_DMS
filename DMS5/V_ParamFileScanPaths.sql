/****** Object:  View [dbo].[V_ParamFileScanPaths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_ParamFileScanPaths
AS
SELECT DISTINCT AJT_parmFileStoragePath, AJT_paramFileType
FROM         dbo.T_Analysis_Tool
WHERE     (AJT_autoScanFolderFlag = 'yes')

GO
