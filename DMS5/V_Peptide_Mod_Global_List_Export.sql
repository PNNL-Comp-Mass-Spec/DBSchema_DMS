/****** Object:  View [dbo].[V_Peptide_Mod_Global_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Peptide_Mod_Global_List_Export
AS
SELECT     Mod_ID, Symbol, Description, SD_Flag, Mass_Correction_Factor, Affected_Residues
FROM         T_Peptide_Mod_Global_List

GO
