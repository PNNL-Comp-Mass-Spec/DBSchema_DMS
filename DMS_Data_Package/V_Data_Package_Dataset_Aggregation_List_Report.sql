/****** Object:  View [dbo].[V_Data_Package_Dataset_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_Aggregation_List_Report]
AS
SELECT Data_Pkg_ID AS ID,
       Dataset,
       COUNT(*) AS Jobs
FROM T_Data_Package_Analysis_Jobs
GROUP BY Dataset, Data_Pkg_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Dataset_Aggregation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
