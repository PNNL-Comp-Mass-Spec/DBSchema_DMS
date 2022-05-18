/****** Object:  View [dbo].[V_OSM_Package_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_OSM_Package_Picklist
As
SELECT ID, Name, CAST(ID AS VARCHAR(12)) + ': ' + Name As Id_with_Name
FROM S_V_OSM_Package_Export   


GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_Picklist] TO [DDL_Viewer] AS [dbo]
GO
