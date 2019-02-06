/****** Object:  View [dbo].[V_Residue_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Residue_List_Report]
AS
SELECT Residue_ID,
       Residue_Symbol As Symbol,
       Description As Abbreviation,
       Amino_Acid_Name As [Amino Acid],
       Monoisotopic_Mass As [Monoisotopic Mass],
       Average_Mass As [Average Mass],
       Empirical_Formula As [Empirical Formula],
       Num_C As [Num C],
       Num_H As [Num H],
       Num_N As [Num N],
       Num_O As [Num O],
       Num_S As [Num S]
FROM dbo.T_Residues


GO
GRANT VIEW DEFINITION ON [dbo].[V_Residue_List_Report] TO [DDL_Viewer] AS [dbo]
GO
