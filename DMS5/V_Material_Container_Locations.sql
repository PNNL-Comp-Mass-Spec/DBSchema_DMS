/****** Object:  View [dbo].[V_Material_Container_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Container_Locations]
AS
SELECT MC.Tag AS Container,
       MC.[Type],
       MC.Status,
       MC.[Comment],
       MC.Created,
       ML.Tag AS Location,
       ML.Freezer_Tag,
       ML.Shelf,
       ML.Rack,
       ML.Row,
       ML.Col,
       ML.ID As Location_ID
FROM T_Material_Containers MC
     INNER JOIN T_Material_Locations ML
       ON MC.Location_ID = ML.ID


GO
