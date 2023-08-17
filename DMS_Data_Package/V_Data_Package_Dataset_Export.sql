/****** Object:  View [dbo].[V_Data_Package_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_Export] AS
SELECT Data_Pkg_ID,
       Dataset_ID,
       Dataset,
       Experiment,
       Instrument,
       Created,
       Item_Added,
       Package_Comment,
       Data_Pkg_ID AS Data_Package_ID
FROM T_Data_Package_Datasets

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Dataset_Export] TO [DDL_Viewer] AS [dbo]
GO
