/****** Object:  Synonym [dbo].[S_Experiment_List] ******/
CREATE SYNONYM [dbo].[S_Experiment_List] FOR [DMS5].[dbo].[T_Experiments]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Experiment_List] TO [DDL_Viewer] AS [dbo]
GO
