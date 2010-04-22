/****** Object:  View [dbo].[V_Param_File_Mass_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Param_File_Mass_Mods
AS
(
SELECT PFMM.*,
       R.Residue_Symbol,
       MCF.Mass_Correction_Tag,
       MCF.Monoisotopic_Mass_Correction,
       SLS.Local_Symbol,
       R.Description AS Residue_Desc,
       PF.Param_File_Name,
       PF.Param_File_Description
       
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
