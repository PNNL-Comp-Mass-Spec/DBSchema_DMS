/****** Object:  View [dbo].[V_Collection_Counts_By_Organism_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Collection_Counts_By_Organism_ID]
AS
SELECT Organism_ID AS organism_id,
       COUNT(Protein_Collection_ID) AS collection_count
FROM dbo.T_Collection_Organism_Xref
GROUP BY Organism_ID


GO
