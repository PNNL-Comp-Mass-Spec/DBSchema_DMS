/****** Object:  View [dbo].[V_MAC_Data_Package_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MAC_Data_Package_Experiments]
AS
SELECT Data_Pkg_ID,
       Experiment_ID,
       Experiment,
       Created,
       Item_Added,
       Package_Comment,
       Data_Pkg_ID AS Data_Package_ID
FROM S_V_Data_Package_Experiments_Export

GO
GRANT VIEW DEFINITION ON [dbo].[V_MAC_Data_Package_Experiments] TO [DDL_Viewer] AS [dbo]
GO
