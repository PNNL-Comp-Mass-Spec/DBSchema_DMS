/****** Object:  View [dbo].[V_RefID_ProteinID_Xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_RefID_ProteinID_Xref
AS
SELECT     dbo.T_Protein_Collection_Members.Original_Reference_ID AS ref_id, dbo.T_Protein_Names.Name AS name, 
                      dbo.T_Protein_Names.Description AS description, dbo.V_Organism_Picker.Organism_Name AS organism, 
                      dbo.T_Protein_Collection_Members.Protein_ID AS protein_id
FROM         dbo.V_Organism_Picker INNER JOIN
                      dbo.T_Collection_Organism_Xref ON dbo.V_Organism_Picker.ID = dbo.T_Collection_Organism_Xref.Organism_ID INNER JOIN
                      dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names.Reference_ID ON 
                      dbo.T_Collection_Organism_Xref.Protein_Collection_ID = dbo.T_Protein_Collection_Members.Protein_Collection_ID

GO
