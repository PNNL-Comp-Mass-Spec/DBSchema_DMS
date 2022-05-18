/****** Object:  View [dbo].[V_OSM_Package_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_OSM_Package_State_Picklist
As
SELECT Name, Description
FROM T_OSM_Package_State   


GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_State_Picklist] TO [DDL_Viewer] AS [dbo]
GO
