/****** Object:  View [dbo].[V_Data_Package_Datasets_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Datasets_Export]
AS
-- This view is used by ad-hoc query "data_package_datasets", defined at https://dmsdev.pnl.gov/config_db/edit_table/ad_hoc_query.db/utility_queries
SELECT Data_Pkg_ID,
       Dataset_ID,
       Dataset,
       Experiment,
       Instrument,
       Created,
       Item_Added,
       Package_Comment,
       Data_Package_ID
FROM S_V_Data_Package_Datasets_Export

GO
