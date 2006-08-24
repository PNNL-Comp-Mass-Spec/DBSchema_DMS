/****** Object:  View [dbo].[V_Param_File_Mass_Mod_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Param_File_Mass_Mod_Info
AS
SELECT     TOP 100 PERCENT dbo.T_Param_Files.Param_File_Name, dbo.T_Param_File_Mass_Mods.Param_File_ID, 
                      dbo.T_Seq_Local_Symbols_List.Local_Symbol, dbo.T_Param_File_Mass_Mods.Mod_Type_Symbol, dbo.T_Residues.Residue_Symbol, 
                      dbo.T_Mass_Correction_Factors.Affected_Atom, dbo.T_Param_File_Mass_Mods.Mass_Correction_ID, 
                      dbo.T_Mass_Correction_Factors.Mass_Correction_Tag, dbo.T_Mass_Correction_Factors.Description, 
                      dbo.T_Mass_Correction_Factors.Monoisotopic_Mass_Correction
FROM         dbo.T_Mass_Correction_Factors INNER JOIN
                      dbo.T_Param_File_Mass_Mods ON 
                      dbo.T_Mass_Correction_Factors.Mass_Correction_ID = dbo.T_Param_File_Mass_Mods.Mass_Correction_ID INNER JOIN
                      dbo.T_Residues ON dbo.T_Param_File_Mass_Mods.Residue_ID = dbo.T_Residues.Residue_ID INNER JOIN
                      dbo.T_Seq_Local_Symbols_List ON dbo.T_Param_File_Mass_Mods.Local_Symbol_ID = dbo.T_Seq_Local_Symbols_List.Local_Symbol_ID INNER JOIN
                      dbo.T_Param_Files ON dbo.T_Param_File_Mass_Mods.Param_File_ID = dbo.T_Param_Files.Param_File_ID
ORDER BY dbo.T_Param_File_Mass_Mods.Param_File_ID, dbo.T_Param_File_Mass_Mods.Mod_Type_Symbol, 
                      dbo.T_Seq_Local_Symbols_List.Local_Symbol_ID, dbo.T_Residues.Residue_Symbol

GO
