/****** Object:  View [dbo].[V_Collection_Member_List_Report_ExtJS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_Member_List_Report_ExtJS
AS
SELECT     dbo.T_Proteins.Protein_ID, dbo.T_Protein_Names.Name, dbo.T_Protein_Names.Description, dbo.T_Proteins.Sequence, dbo.T_Proteins.Length, 
                      dbo.T_Proteins.Molecular_Formula AS mol_formula, ROUND(dbo.T_Proteins.Monoisotopic_Mass, 4) AS monoisotopic_mass, 
                      ROUND(dbo.T_Proteins.Average_Mass, 4) AS average_mass, dbo.T_Protein_Collection_Members.Protein_Collection_ID AS collection_id, 
                      dbo.T_Protein_Names.Reference_ID AS id, dbo.T_Protein_Collections.FileName AS collection_name
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Proteins ON dbo.T_Protein_Collection_Members.Protein_ID = dbo.T_Proteins.Protein_ID INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names.Reference_ID INNER JOIN
                      dbo.T_Protein_Collections ON dbo.T_Protein_Collection_Members.Protein_Collection_ID = dbo.T_Protein_Collections.Protein_Collection_ID

GO
