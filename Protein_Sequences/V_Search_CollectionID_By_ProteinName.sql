/****** Object:  View [dbo].[V_Search_CollectionID_By_ProteinName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Search_CollectionID_By_ProteinName
AS
SELECT     dbo.T_Protein_Collection_Members.Protein_Collection_ID AS Collection_ID, dbo.T_Protein_Names.Name, 'collectionIDByProteinName' AS Value_type
FROM         dbo.T_Protein_Collection_Members INNER JOIN
                      dbo.T_Protein_Names ON dbo.T_Protein_Collection_Members.Original_Reference_ID = dbo.T_Protein_Names.Reference_ID

GO
