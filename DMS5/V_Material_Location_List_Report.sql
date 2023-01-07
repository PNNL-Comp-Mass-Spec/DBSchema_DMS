/****** Object:  View [dbo].[V_Material_Location_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Location_List_Report]
AS
SELECT ML.Tag AS location,
       T_Material_Freezers.freezer,
       T_Material_Freezers.freezer_tag,
       ML.shelf,
       ML.rack,
       ML.row,
       ML.col,
       -- Unused: ML.barcode,
       ML.comment,
       ML.container_limit,
       COUNT(MC.ID) AS containers,
       ML.Container_Limit - COUNT(MC.ID) AS available,
       ML.status,
       ML.ID AS id
FROM dbo.T_Material_Locations ML
     INNER JOIN T_Material_Freezers
       ON ML.Freezer_Tag = T_Material_Freezers.Freezer_Tag
     LEFT OUTER JOIN dbo.T_Material_Containers MC
       ON ML.ID = MC.Location_ID
GROUP BY ML.Tag, T_Material_Freezers.Freezer, T_Material_Freezers.Freezer_Tag,
         ML.Shelf, ML.Rack, ML.Row, ML.Col,
         ML.Comment, ML.Container_Limit, ML.Status, ML.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Location_List_Report] TO [DDL_Viewer] AS [dbo]
GO
