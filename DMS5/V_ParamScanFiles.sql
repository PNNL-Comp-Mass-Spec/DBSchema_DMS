/****** Object:  View [dbo].[V_ParamScanFiles] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_ParamScanFiles
AS
SELECT DISTINCT 
                      dbo.T_Param_Files.Param_File_ID, dbo.T_Param_Files.Param_File_Name, dbo.T_Param_Files.Param_File_Description, 
                      dbo.T_Param_Files.Param_File_Type_ID, dbo.T_Param_Files.Date_Created, dbo.T_Param_Files.Date_Modified, dbo.T_Param_Files.Valid, 
                      dbo.T_Analysis_Tool.AJT_parmFileStoragePath
FROM         dbo.T_Analysis_Tool INNER JOIN
                      dbo.T_Param_Files ON dbo.T_Analysis_Tool.AJT_paramFileType = dbo.T_Param_Files.Param_File_Type_ID
WHERE     (dbo.T_Analysis_Tool.AJT_autoScanFolderFlag = 'yes')

GO
