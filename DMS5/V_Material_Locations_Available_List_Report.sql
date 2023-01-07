/****** Object:  View [dbo].[V_Material_Locations_Available_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Locations_Available_List_Report]
AS
SELECT location,
       freezer,
       shelf,
       rack,
       row,
       col,
       comment,
       container_limit,
       containers,
       available,
       'New Container' AS action,
       id
FROM dbo.V_Material_Location_List_Report
WHERE Available > 0 AND
      Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Locations_Available_List_Report] TO [DDL_Viewer] AS [dbo]
GO
