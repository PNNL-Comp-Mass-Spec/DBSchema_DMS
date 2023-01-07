/****** Object:  View [dbo].[V_Material_Containers_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Containers_Picklist]
AS
SELECT MC.Tag AS container,
       MC.type,
       MC.status,
       MC.comment,
       L.Tag AS location,
       MC.SortKey AS sort_key
FROM T_Material_Containers MC
     INNER JOIN T_Material_Locations L
       ON MC.Location_ID = L.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Picklist] TO [DDL_Viewer] AS [dbo]
GO
