/****** Object:  Synonym [dbo].[s_standardize_protein_collection_list] ******/
CREATE SYNONYM [dbo].[s_standardize_protein_collection_list] FOR [ProteinSeqs].[Protein_Sequences].[dbo].[standardize_protein_collection_list]
GO
GRANT VIEW DEFINITION ON [dbo].[s_standardize_protein_collection_list] TO [DDL_Viewer] AS [dbo]
GO
