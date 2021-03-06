/****** Object:  View [dbo].[V_Param_File_Mass_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Mass_Mods]
AS
(
SELECT PFMM.*,
       R.Residue_Symbol,
       MCF.Mass_Correction_Tag,
       MCF.Monoisotopic_Mass,
       SLS.Local_Symbol,
       R.Description AS Residue_Desc,
       PF.Param_File_Name,
       PF.Param_File_Description,
       ' || Mod Type || Residue || Mod Name (DMS) || Mod Name (UniMod) || Mod Mass ||' AS TableCode_Header,
       ' | ' + CASE PFMM.Mod_Type_Symbol 
               WHEN 'S' THEN 'Static'
               WHEN 'D' THEN 'Dynamic'
               WHEN 'T' THEN 'Static Terminal Peptide'
               WHEN 'P' THEN 'Static Terminal Protein'
               WHEN 'I' THEN 'Isotopic'
               ELSE PFMM.Mod_Type_Symbol 
               END +
       ' | ' + R.Description + 
       ' | ' + MCF.Mass_Correction_Tag + 
       ' | ' + CASE WHEN MCF.Original_Source LIKE '%UniMod%' Then MCF.Original_Source_Name ELSE '' End + 
       ' | ' + Cast(MCF.Monoisotopic_Mass as varchar(12)) + 
       ' | ' AS TableCode_Row
FROM T_Param_File_Mass_Mods PFMM
     INNER JOIN T_Residues R
       ON PFMM.Residue_ID = R.Residue_ID
     INNER JOIN T_Mass_Correction_Factors MCF
       ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID
     INNER JOIN T_Seq_Local_Symbols_List SLS
       ON PFMM.Local_Symbol_ID = SLS.Local_Symbol_ID
     INNER JOIN dbo.T_Param_Files PF
       ON PFMM.Param_File_ID = PF.Param_File_ID
)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Mass_Mods] TO [DDL_Viewer] AS [dbo]
GO
