/****** Object:  View [dbo].[V_Material_Locations_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Locations_List_Report
AS
SELECT     dbo.T_Material_Locations.Tag AS Location, dbo.T_Material_Locations.Freezer, dbo.T_Material_Locations.Shelf, dbo.T_Material_Locations.Rack, 
                      dbo.T_Material_Locations.Row, dbo.T_Material_Locations.Col, dbo.T_Material_Locations.Barcode, dbo.T_Material_Locations.Comment, 
                      dbo.T_Material_Locations.Container_Limit AS Limit, COUNT(dbo.T_Material_Containers.ID) AS Containers, 
                      dbo.T_Material_Locations.Container_Limit - COUNT(dbo.T_Material_Containers.ID) AS Available, dbo.T_Material_Locations.Status, 
                      dbo.T_Material_Locations.ID AS [#ID]
FROM         dbo.T_Material_Locations LEFT OUTER JOIN
                      dbo.T_Material_Containers ON dbo.T_Material_Locations.ID = dbo.T_Material_Containers.Location_ID
GROUP BY dbo.T_Material_Locations.ID, dbo.T_Material_Locations.Freezer, dbo.T_Material_Locations.Shelf, dbo.T_Material_Locations.Rack, 
                      dbo.T_Material_Locations.Row, dbo.T_Material_Locations.Barcode, dbo.T_Material_Locations.Comment, dbo.T_Material_Locations.Tag, 
                      dbo.T_Material_Locations.Col, dbo.T_Material_Locations.Status, dbo.T_Material_Locations.Container_Limit
HAVING      (dbo.T_Material_Locations.Status = 'Active')

GO
