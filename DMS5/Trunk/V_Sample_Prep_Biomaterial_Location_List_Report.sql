/****** Object:  View [dbo].[V_Sample_Prep_Biomaterial_Location_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Sample_Prep_Biomaterial_Location_List_Report]
AS
SELECT
  TX.ID,
  Request_Name,
  CC_Name AS Biomaterial,
  dbo.T_Material_Containers.Tag AS Container,
  dbo.T_Material_Locations.Tag AS Location
FROM
  ( SELECT
      Request_Name,
      ID,
      Item
    FROM
      T_Sample_Prep_Request
      CROSS APPLY dbo.MakeTableFromList(REPLACE(Cell_Culture_List, ';', ','))
    WHERE
      ( NOT ( ISNULL(Cell_Culture_List, '') IN ( '(none)', 'none', '' ) )
      )
      AND ( NOT Item IN ( '(none)', 'none', '' )
          )
  ) TX
  LEFT OUTER JOIN T_Cell_Culture ON CC_Name = TX.Item
  INNER JOIN T_Material_Containers ON T_Cell_Culture.CC_Container_ID = T_Material_Containers.ID
  INNER JOIN T_Material_Locations ON T_Material_Containers.Location_ID = T_Material_Locations.ID     


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Biomaterial_Location_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Biomaterial_Location_List_Report] TO [PNL\D3M580] AS [dbo]
GO
