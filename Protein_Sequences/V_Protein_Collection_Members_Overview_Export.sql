/****** Object:  View [dbo].[V_Protein_Collection_Members_Overview_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Members_Overview_Export]
AS
SELECT PCM.Protein_Collection_ID,
       PC.Collection_Name AS Protein_Collection_Name,
       PN.Name AS Protein_Name,
       PN.Description,
       dbo.T_Proteins.Monoisotopic_Mass,
       dbo.T_Proteins.Average_Mass,
       dbo.T_Proteins.Length AS Residue_Count,
       dbo.T_Proteins.Molecular_Formula,
       dbo.T_Proteins.Protein_ID,
       PN.Reference_ID,
       dbo.T_Proteins.SHA1_Hash,
       PCM.Member_ID,
       PCM.Sorting_Index
FROM dbo.T_Protein_Collection_Members PCM
     INNER JOIN dbo.T_Proteins
       ON PCM.Protein_ID = dbo.T_Proteins.Protein_ID
     INNER JOIN dbo.T_Protein_Names PN
       ON PCM.Protein_ID = PN.Protein_ID 
          AND
          PCM.Original_Reference_ID = PN.Reference_ID
     INNER JOIN dbo.T_Protein_Collections PC
       ON PCM.Protein_Collection_ID 
          = PC.Protein_Collection_ID

GO
