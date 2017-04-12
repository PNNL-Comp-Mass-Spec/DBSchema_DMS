/****** Object:  Synonym [dbo].[S_Sample_Submission_List] ******/
CREATE SYNONYM [dbo].[S_Sample_Submission_List] FOR [DMS5].[dbo].[T_Sample_Submission]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Sample_Submission_List] TO [DDL_Viewer] AS [dbo]
GO
