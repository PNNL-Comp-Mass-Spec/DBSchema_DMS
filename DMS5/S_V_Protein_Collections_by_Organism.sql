/****** Object:  Synonym [dbo].[S_V_Protein_Collections_by_Organism] ******/
CREATE SYNONYM [dbo].[S_V_Protein_Collections_by_Organism] FOR [ProteinSeqs].[Protein_Sequences].[dbo].[V_Protein_Collections_By_Organism]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Protein_Collections_by_Organism] TO [DDL_Viewer] AS [dbo]
GO
