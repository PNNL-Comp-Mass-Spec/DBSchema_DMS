/****** Object:  View [dbo].[V_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collections]
AS
SELECT protein_collection_id,
       Collection_Name + ' (' + CAST(NumProteins AS varchar) + ' Entries)' AS display,
       collection_name,
       primary_annotation_type_id,
       description,
       contents_encrypted,
       collection_type_id,
       collection_state_id,
       NumProteins As num_proteins,
       NumResidues As num_residues
FROM dbo.T_Protein_Collections


GO
