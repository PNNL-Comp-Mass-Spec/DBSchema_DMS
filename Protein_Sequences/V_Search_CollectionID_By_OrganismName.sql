/****** Object:  View [dbo].[V_Search_CollectionID_By_OrganismName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Search_CollectionID_By_OrganismName
AS
SELECT     dbo.T_Protein_Collections.Protein_Collection_ID AS Collection_ID, dbo.V_Protein_Collections_By_Organism.Organism_Name AS Name, 
                      'collectionIDByOrganismName' AS Value_type
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.V_Protein_Collections_By_Organism ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.V_Protein_Collections_By_Organism.Protein_Collection_ID

GO
