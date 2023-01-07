/****** Object:  View [dbo].[V_Param_File_Mass_Mods_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Mass_Mods_List_Report]
AS
(
SELECT PFMM.mod_entry_id,
       PFMM.param_file_id,
       PFMM.Mod_Type_Symbol AS mod_type,
       R.Residue_Symbol AS residue,
       R.Description AS residue_desc,
       -- PFMM.local_symbol_id,
       SLS.Local_Symbol AS symbol,
       PFMM.Mass_Correction_ID AS mod_id,
       MCF.mass_correction_tag,
       MCF.Monoisotopic_Mass AS mono_mass,
       MCF.Description AS mod_description,
       ISNULL(MCF.empirical_formula, '') AS empirical_formula,
       MCF.original_source,
       MCF.original_source_name,
       PF.param_file_name,
       PF.param_file_description,
       Tool.AJT_toolName AS primary_tool
FROM T_Param_File_Mass_Mods PFMM
     INNER JOIN T_Residues R
       ON PFMM.Residue_ID = R.Residue_ID
     INNER JOIN T_Mass_Correction_Factors MCF
       ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID
     INNER JOIN T_Seq_Local_Symbols_List SLS
       ON PFMM.Local_Symbol_ID = SLS.Local_Symbol_ID
     INNER JOIN dbo.T_Param_Files PF
       ON PFMM.Param_File_ID = PF.Param_File_ID
     INNER JOIN T_Param_File_Types PFT
       ON PF.Param_File_Type_ID = PFT.Param_File_Type_ID
     INNER JOIN T_Analysis_Tool Tool
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID
)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Mass_Mods_List_Report] TO [DDL_Viewer] AS [dbo]
GO
