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
       ISNULL(MCF.Empirical_Formula, '') AS Empirical_Formula,
       ISNULL(MQM.Mod_Title, '') AS MaxQuant_Mod_Name,
       CASE WHEN MCF.Original_Source = 'UniMod' THEN MCF.Original_Source_Name ELSE '' END AS UniMod_Mod_Name,
       CASE PFMM.Mod_Type_Symbol
           WHEN 'D' THEN 'Dyn'
           WHEN 'S' THEN 'Stat'
           WHEN 'T' THEN 'PepTerm'
           WHEN 'P' THEN 'ProtTerm'
           WHEN 'I' THEN 'Iso'
           ELSE PFMM.Mod_Type_Symbol
       END + '_' + R.Abbreviation + '_' + MCF.Mass_Correction_Tag + '_' + 
       MCF.Original_Source_Name AS Mod_Code,
       CASE PFMM.Mod_Type_Symbol
           WHEN 'D' THEN 'Dyn'
           WHEN 'S' THEN 'Stat'
           WHEN 'T' THEN 'PepTerm'
           WHEN 'P' THEN 'ProtTerm'
           WHEN 'I' THEN 'Iso'
           ELSE PFMM.Mod_Type_Symbol
       END + '_' + R.Abbreviation + '_' + MCF.Mass_Correction_Tag + '_' + 
       MCF.Original_Source_Name + '_' + S.Local_Symbol AS Mod_Code_With_Symbol
FROM dbo.T_Mass_Correction_Factors MCF
     INNER JOIN dbo.T_Param_File_Mass_Mods PFMM
       ON MCF.Mass_Correction_ID = PFMM.Mass_Correction_ID
     INNER JOIN dbo.T_Residues R
       ON PFMM.Residue_ID = R.Residue_ID
     INNER JOIN dbo.T_Seq_Local_Symbols_List S
       ON PFMM.Local_Symbol_ID = S.Local_Symbol_ID
     INNER JOIN dbo.T_Param_Files PF
       ON PFMM.Param_File_ID = PF.Param_File_ID
     LEFT OUTER JOIN dbo.T_MaxQuant_Mods MQM
       ON MQM.Mod_ID = PFMM.MaxQuant_Mod_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Mass_Mod_Info] TO [DDL_Viewer] AS [dbo]
GO
