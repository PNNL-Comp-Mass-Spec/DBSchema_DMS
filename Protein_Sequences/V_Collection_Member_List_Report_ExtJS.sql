/****** Object:  View [dbo].[V_Collection_Member_List_Report_ExtJS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Collection_Member_List_Report_ExtJS]
AS
SELECT dbo.T_Proteins.Protein_ID,
       PN.Name,
       PN.Description,
       dbo.T_Proteins.Sequence,
       dbo.T_Proteins.Length,
       dbo.T_Proteins.Molecular_Formula AS mol_formula,
       ROUND(dbo.T_Proteins.Monoisotopic_Mass, 4) AS monoisotopic_mass,
       ROUND(dbo.T_Proteins.Average_Mass, 4) AS average_mass,
       PCM.Protein_Collection_ID AS collection_id,
       PN.Reference_ID AS id,
       PC.Collection_Name
FROM dbo.T_Protein_Collection_Members PCM
     INNER JOIN dbo.T_Proteins
       ON PCM.Protein_ID = dbo.T_Proteins.Protein_ID
     INNER JOIN dbo.T_Protein_Names PN
       ON PCM.Original_Reference_ID = PN.Reference_ID
     INNER JOIN dbo.T_Protein_Collections PC
       ON PCM.Protein_Collection_ID 
          = PC.Protein_Collection_ID

GO
