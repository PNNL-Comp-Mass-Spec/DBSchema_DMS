/****** Object:  View [dbo].[V_Data_Package_Experiments_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Experiments_Export]
AS
SELECT DPE.Data_Pkg_ID,
       DPE.Experiment_ID,
       E.Experiment_Num AS Experiment,
       E.Ex_Created AS Created,
       DPE.Item_Added,
       DPE.Package_Comment,
       DPE.Data_Pkg_ID AS Data_Package_ID
FROM T_Data_Package_Experiments DPE
     INNER JOIN S_Experiment_List E
       ON DPE.Experiment_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Experiments_Export] TO [DDL_Viewer] AS [dbo]
GO
