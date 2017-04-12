/****** Object:  Synonym [dbo].[S_Data_Package_Details] ******/
CREATE SYNONYM [dbo].[S_Data_Package_Details] FOR [DMS_Data_Package].[dbo].[V_Data_Package_Detail_Report]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Data_Package_Details] TO [DDL_Viewer] AS [dbo]
GO
