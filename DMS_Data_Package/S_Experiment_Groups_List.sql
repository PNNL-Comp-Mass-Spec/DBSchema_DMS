/****** Object:  Synonym [dbo].[S_Experiment_Groups_List] ******/
CREATE SYNONYM [dbo].[S_Experiment_Groups_List] FOR [DMS5].[dbo].[T_Experiment_Groups]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Experiment_Groups_List] TO [DDL_Viewer] AS [dbo]
GO
