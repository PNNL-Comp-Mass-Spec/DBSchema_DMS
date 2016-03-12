/****** Object:  View [dbo].[V_Material_Locations_Available_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Locations_Available_List_Report
AS
SELECT     Location, Freezer, Shelf, Rack, Row, Col, Barcode, Comment, Limit, Containers, Available, 'New Container' AS Action, [#ID]
FROM         dbo.V_Material_Locations_List_Report
WHERE     (Available > 0) AND (Status = 'Active')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Locations_Available_List_Report] TO [PNL\D3M578] AS [dbo]
GO
