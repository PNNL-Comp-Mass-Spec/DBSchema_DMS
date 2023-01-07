/****** Object:  View [dbo].[V_Material_Locations_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Locations_Picklist]
AS
SELECT location,
       comment,
       freezer,
       shelf,
       rack,
       row,
       col,
       container_limit,
       containers,
       available
FROM dbo.V_Material_Location_List_Report
WHERE (Status = 'Active') AND
      (Available > 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Locations_Picklist] TO [DDL_Viewer] AS [dbo]
GO
