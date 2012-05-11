/****** Object:  View [dbo].[V_Website_Protein_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Website_Protein_Details
AS
SELECT     dbo.T_Protein_Names.Reference_ID AS ref_id, dbo.T_Protein_Names.Name AS name, dbo.T_Protein_Names.Description AS description, 
                      dbo.T_Proteins.Sequence AS sequence, dbo.T_Proteins.Length AS length, dbo.T_Proteins.Molecular_Formula AS molecular_formula, 
                      dbo.T_Proteins.Monoisotopic_Mass AS monoisotopic_mass, dbo.T_Proteins.Average_Mass AS average_mass, 
                      dbo.T_Proteins.SHA1_Hash AS sha1_hash, dbo.T_Proteins.DateCreated AS date_created, dbo.T_Proteins.Protein_ID AS protein_id
FROM         dbo.T_Proteins INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Proteins.Protein_ID = dbo.T_Protein_Names.Protein_ID
WHERE     (dbo.T_Protein_Names.Reference_ID = 1150)

GO
