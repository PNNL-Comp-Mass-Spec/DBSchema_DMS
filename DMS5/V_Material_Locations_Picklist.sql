/****** Object:  View [dbo].[V_Material_Locations_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Locations_Picklist]
AS
SELECT     Location, Comment, Freezer, Shelf, Rack, Row, Col, Limit, Containers, Available
FROM         dbo.V_Material_Locations_List_Report
WHERE     (Status = 'Active') AND (Available > 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Locations_Picklist] TO [DDL_Viewer] AS [dbo]
GO
