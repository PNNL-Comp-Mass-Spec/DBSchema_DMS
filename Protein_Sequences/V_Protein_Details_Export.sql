/****** Object:  View [dbo].[V_Protein_Details_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Details_Export
AS
SELECT dbo.T_Protein_Names.Name, dbo.T_Proteins.Protein_ID, 
    dbo.T_Proteins.Sequence, dbo.T_Proteins.Length, 
    dbo.T_Proteins.Molecular_Formula, 
    dbo.T_Proteins.Monoisotopic_Mass, 
    dbo.T_Proteins.Average_Mass, dbo.T_Proteins.SHA1_Hash, 
    dbo.T_Proteins.DateCreated, dbo.T_Proteins.DateModified, 
    dbo.T_Proteins.IsEncrypted
FROM dbo.T_Proteins INNER JOIN
    dbo.T_Protein_Names ON 
    dbo.T_Proteins.Protein_ID = dbo.T_Protein_Names.Protein_ID

GO
