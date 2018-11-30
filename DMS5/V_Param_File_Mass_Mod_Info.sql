/****** Object:  View [dbo].[V_Param_File_Mass_Mod_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Mass_Mod_Info]
AS
SELECT PF.Param_File_Name,
       PFMM.Param_File_ID,
       S.Local_Symbol,
       PFMM.Mod_Type_Symbol,
       R.Residue_Symbol,
       MCF.Affected_Atom,
       PFMM.Mass_Correction_ID,
       MCF.Mass_Correction_Tag,
       MCF.Description,
       MCF.Monoisotopic_Mass,
       ISNULL(MCF.Empirical_Formula, '') AS Empirical_Formula
FROM dbo.T_Mass_Correction_Factors MCF
     INNER JOIN dbo.T_Param_File_Mass_Mods PFMM
       ON MCF.Mass_Correction_ID = PFMM.Mass_Correction_ID
     INNER JOIN dbo.T_Residues R
       ON PFMM.Residue_ID = R.Residue_ID
     INNER JOIN dbo.T_Seq_Local_Symbols_List S
       ON PFMM.Local_Symbol_ID = S.Local_Symbol_ID
     INNER JOIN dbo.T_Param_Files PF
       ON PFMM.Param_File_ID = PF.Param_File_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Mass_Mod_Info] TO [DDL_Viewer] AS [dbo]
GO
