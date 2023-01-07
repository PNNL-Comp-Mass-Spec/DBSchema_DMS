/****** Object:  View [dbo].[V_Material_Location_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Location_Detail_Report]
AS
SELECT ML.ID AS id,
       ML.Tag AS location,
       MF.freezer,
       MF.freezer_tag,
       ML.shelf,
       ML.rack,
       ML.row,
       ML.col,
       -- Unused: ML.barcode,
       ML.comment,
       ML.container_limit,
       COUNT(MC.ID) AS containers,
       ML.Container_Limit - COUNT(MC.ID) AS available,
       ML.status
FROM dbo.T_Material_Locations ML
     INNER JOIN T_Material_Freezers MF
       ON ML.Freezer_Tag = MF.Freezer_Tag
     LEFT OUTER JOIN dbo.T_Material_Containers MC
       ON ML.ID = MC.Location_ID
GROUP BY ML.ID, MF.Freezer, MF.Freezer_Tag, ML.Shelf, ML.Rack, ML.Row,
         ML.Comment, ML.Tag, ML.Col, ML.Status, ML.Container_Limit


GO
