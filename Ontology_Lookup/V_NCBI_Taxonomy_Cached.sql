/****** Object:  View [dbo].[V_NCBI_Taxonomy_Cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NCBI_Taxonomy_Cached]
AS
SELECT Tax_ID,
       Name,
       Rank,
       Parent_Tax_ID,
       Synonyms,
       Synonym_List
FROM dbo.T_NCBI_Taxonomy_Cached


GO
GRANT VIEW DEFINITION ON [dbo].[V_NCBI_Taxonomy_Cached] TO [DDL_Viewer] AS [dbo]
GO
