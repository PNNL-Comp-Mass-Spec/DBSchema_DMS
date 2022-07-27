/****** Object:  View [dbo].[V_Search_CollectionID_By_CollectionName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Search_CollectionID_By_CollectionName]
AS
SELECT Protein_Collection_ID AS Collection_ID,
       Collection_Name AS Name,
       'collectionIDByCollectionName' AS Value_type
FROM dbo.T_Protein_Collections

GO
