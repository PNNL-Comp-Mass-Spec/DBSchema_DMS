/****** Object:  View [dbo].[V_Material_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Locations]
AS
SELECT ID AS Location_ID,
       Freezer_Tag,
       Shelf,
       Rack,
       Row,
       Col,
       Status,
       Barcode,
       Comment,
       Container_Limit,
       Tag AS Location
FROM T_Material_Locations


GO
