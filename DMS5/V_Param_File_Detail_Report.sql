/****** Object:  View [dbo].[V_Param_File_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Detail_Report]
AS
SELECT PF.Param_File_ID AS id,
       PF.Param_File_Name AS name,
       PFT.Param_File_Type AS type,
       PFT.Param_File_Type_ID AS type_id,
       PF.Param_File_Description AS description,
       Tool.AJT_toolName AS primary_tool,
       PF.Date_Created AS created,
       PF.Date_Modified AS modified,
       PF.Job_Usage_Count AS job_usage_count,
       PF.Job_Usage_Last_Year AS job_usage_last_year,
       dbo.udfCombinePaths(Tool.ajt_parmfilestoragepath, PF.Param_File_Name) AS file_path,
       PF.valid,
       dbo.GetParamFileMassModsTableCode(PF.Param_File_ID) AS mass_mods,
       dbo.GetMaxQuantMassModsList(PF.Param_File_ID) AS maxquant_mods,
       PF.Mod_List As mod_code_list,
       dbo.GetParamFileMassModCodeList(PF.param_file_id, 1) As mod_codes_with_symbols
FROM T_Param_Files PF
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID
     INNER JOIN T_Analysis_Tool Tool
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
