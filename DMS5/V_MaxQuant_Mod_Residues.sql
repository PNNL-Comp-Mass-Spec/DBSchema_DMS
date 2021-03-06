/****** Object:  View [dbo].[V_MaxQuant_Mod_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MaxQuant_Mod_Residues]
AS
SELECT ModInfo.Mod_ID,
       ModInfo.Mod_Title,
       ModInfo.Mod_Position,
       R.Residue_Symbol,
       R.Residue_ID,
       MCF.Mass_Correction_ID,
       MCF.Mass_Correction_Tag
FROM T_MaxQuant_Mod_Residues AS ModResidues
     INNER JOIN T_MaxQuant_Mods AS ModInfo
       ON ModResidues.Mod_ID = ModInfo.Mod_ID
     INNER JOIN T_Residues AS R
       ON ModResidues.Residue_ID = R.Residue_ID
     LEFT OUTER JOIN T_Mass_Correction_Factors AS MCF
       ON ModInfo.Mass_Correction_ID = MCF.Mass_Correction_ID


GO
