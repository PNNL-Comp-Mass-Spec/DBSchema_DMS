/****** Object:  View [dbo].[V_Param_File_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Param_File_Picklist
AS
SELECT TOP 100 PERCENT dbo.T_Param_Files.Param_File_Name AS
     Name, 
    dbo.T_Param_Files.Param_File_Description AS [Desc], 
    dbo.T_Analysis_Tool.AJT_toolName AS ToolName
FROM dbo.T_Param_Files INNER JOIN
    dbo.T_Analysis_Tool ON 
    dbo.T_Param_Files.Param_File_Type_ID = dbo.T_Analysis_Tool.AJT_paramFileType
WHERE (dbo.T_Param_Files.Valid = 1)
ORDER BY dbo.T_Param_Files.Param_File_Name

GO
