/****** Object:  Synonym [dbo].[S_ValidateAnalysisJobProteinParameters] ******/
CREATE SYNONYM [dbo].[S_ValidateAnalysisJobProteinParameters] FOR [ProteinSeqs].[Protein_Sequences].[dbo].[ValidateAnalysisJobProteinParameters]
GO
GRANT VIEW DEFINITION ON [dbo].[S_ValidateAnalysisJobProteinParameters] TO [DDL_Viewer] AS [dbo]
GO
