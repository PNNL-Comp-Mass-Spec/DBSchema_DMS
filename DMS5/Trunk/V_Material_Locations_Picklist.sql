/****** Object:  View [dbo].[V_Material_Locations_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Locations_Picklist
AS
SELECT     Location, Comment, Freezer, Shelf, Rack, Row, Col, Containers, Status
FROM         dbo.V_Material_Locations_List_Report

GO
