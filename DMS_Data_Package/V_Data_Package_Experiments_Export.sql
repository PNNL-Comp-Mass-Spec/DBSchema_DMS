/****** Object:  View [dbo].[V_Data_Package_Experiments_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Experiments_Export]
AS
SELECT Data_Pkg_ID,
       Experiment_ID,
       Experiment,
       Created,
       Item_Added,
       Package_Comment,
       Data_Pkg_ID AS Data_Package_ID
FROM T_Data_Package_Experiments

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Experiments_Export] TO [DDL_Viewer] AS [dbo]
GO
