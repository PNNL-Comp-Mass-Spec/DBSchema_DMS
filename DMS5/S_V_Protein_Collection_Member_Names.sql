/****** Object:  Synonym [dbo].[S_V_Protein_Collection_Member_Names] ******/
CREATE SYNONYM [dbo].[S_V_Protein_Collection_Member_Names] FOR [ProteinSeqs].[Protein_Sequences].[dbo].[V_Protein_Collection_Member_Names_Export]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Protein_Collection_Member_Names] TO [DDL_Viewer] AS [dbo]
GO
