/****** Object:  View [dbo].[V_Missing_Archive_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Missing_Archive_Entries]
AS
SELECT protein_collection_id,
       collection_name,
       authentication_hash,
       DateModified As date_modified,
       collection_type_id,
       NumProteins As num_proteins
FROM dbo.T_Protein_Collections
WHERE (NOT (Authentication_Hash IN ( SELECT Authentication_Hash
                                     FROM T_Archived_Output_Files )))


GO
