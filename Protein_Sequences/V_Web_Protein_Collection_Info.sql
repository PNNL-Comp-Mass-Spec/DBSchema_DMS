/****** Object:  View [dbo].[V_Web_Protein_Collection_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Web_Protein_Collection_Info]
AS
SELECT PC.Collection_Name AS Name,
       dbo.V_Organism_Picker.Organism_Name AS [Primary Organism Name],
       PC.Description,
       PC.NumProteins AS [Protein Count],
       PC.NumResidues AS [Residue Count],
       PC.DateCreated AS Created,
       PC.Protein_Collection_ID AS Collection_ID
FROM dbo.T_Protein_Collections PC
     INNER JOIN dbo.T_Collection_Organism_Xref
       ON PC.Protein_Collection_ID = dbo.T_Collection_Organism_Xref.Protein_Collection_ID
     INNER JOIN dbo.V_Organism_Picker
       ON dbo.T_Collection_Organism_Xref.Organism_ID = dbo.V_Organism_Picker.ID

GO
