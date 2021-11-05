/****** Object:  View [dbo].[V_Param_File_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Detail_Report]
AS
SELECT PF.Param_File_ID AS ID,
       PF.Param_File_Name AS [Name],
       PFT.Param_File_Type AS [Type],
       PFT.Param_File_Type_ID AS [Type_ID],
       PF.Param_File_Description AS Description,
       Tool.AJT_toolName AS [Primary Tool],
       PF.Date_Created AS Created,
       PF.Date_Modified AS Modified,
       PF.Job_Usage_Count AS [Job Usage Count],
       PF.Job_Usage_Last_Year AS [Job Usage Last Year],
       dbo.udfCombinePaths(Tool.AJT_parmFileStoragePath, PF.Param_File_Name) AS File_Path,
       PF.Valid,
       dbo.GetParamFileMassModsTableCode(PF.Param_File_ID) AS Mass_Mods,
       dbo.GetMaxQuantMassModsList(PF.Param_File_ID) AS MaxQuant_Mods,
       PF.Mod_List As [Mod Code List],
       dbo.GetParamFileMassModCodeList(PF.Param_File_ID, 1) As [Mod Codes With Symbols]
FROM T_Param_Files PF
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID
     INNER JOIN T_Analysis_Tool Tool
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
