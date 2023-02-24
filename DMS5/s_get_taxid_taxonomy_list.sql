/****** Object:  Synonym [dbo].[S_GetTaxIDTaxonomyList] ******/
CREATE SYNONYM [dbo].[S_GetTaxIDTaxonomyList] FOR [Ontology_Lookup].[dbo].[get_taxid_taxonomy_list]
GO
GRANT VIEW DEFINITION ON [dbo].[S_GetTaxIDTaxonomyList] TO [DDL_Viewer] AS [dbo]
GO
