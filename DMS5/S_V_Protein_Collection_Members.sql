/****** Object:  Synonym [dbo].[S_V_Protein_Collection_Members] ******/
CREATE SYNONYM [dbo].[S_V_Protein_Collection_Members] FOR [ProteinSeqs].[Protein_Sequences].[dbo].[V_Protein_Collection_Members_Export]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Protein_Collection_Members] TO [DDL_Viewer] AS [dbo]
GO
