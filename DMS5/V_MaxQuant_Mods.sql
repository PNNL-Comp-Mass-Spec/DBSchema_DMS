/****** Object:  View [dbo].[V_MaxQuant_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MaxQuant_Mods]
AS
SELECT ModInfo.Mod_ID,
       ModInfo.Mod_Title,
       ModInfo.Mod_Position,
       ModInfo.Composition,
       ModInfo.Mass_Correction_ID,
       MCF.Mass_Correction_Tag
FROM T_MaxQuant_Mods AS ModInfo
     LEFT OUTER JOIN T_Mass_Correction_Factors AS MCF
       ON ModInfo.Mass_Correction_ID = MCF.Mass_Correction_ID


GO
