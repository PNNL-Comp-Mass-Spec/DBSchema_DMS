/****** Object:  View [dbo].[V_Web_Protein_Collection_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Web_Protein_Collection_Info
AS
SELECT     dbo.T_Protein_Collections.FileName AS Name, dbo.V_Organism_Picker.Organism_Name AS [Primary Organism Name], 
                      dbo.T_Protein_Collections.Description, dbo.T_Protein_Collections.NumProteins AS [Protein Count], 
                      dbo.T_Protein_Collections.NumResidues AS [Residue Count], dbo.T_Protein_Collections.DateCreated AS Created, 
                      dbo.T_Protein_Collections.Protein_Collection_ID AS Collection_ID
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.T_Collection_Organism_Xref ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.T_Collection_Organism_Xref.Protein_Collection_ID INNER JOIN
                      dbo.V_Organism_Picker ON dbo.T_Collection_Organism_Xref.Organism_ID = dbo.V_Organism_Picker.ID

GO
