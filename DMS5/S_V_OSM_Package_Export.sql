/****** Object:  Synonym [dbo].[S_V_OSM_Package_Export] ******/
CREATE SYNONYM [dbo].[S_V_OSM_Package_Export] FOR [DMS_Data_Package].[dbo].[T_OSM_Package]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_OSM_Package_Export] TO [DDL_Viewer] AS [dbo]
GO
