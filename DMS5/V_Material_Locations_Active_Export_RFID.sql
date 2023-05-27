/****** Object:  View [dbo].[V_Material_Locations_Active_Export_RFID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Locations_Active_Export_RFID]
AS
SELECT ML.Tag AS location,
       T_Material_Freezers.freezer,
       T_Material_Freezers.freezer_tag,
       ML.shelf,
       ML.comment,
       ML.ID AS id,
       ML.RFID_Hex_ID AS hex_id
FROM dbo.T_Material_Locations ML
     INNER JOIN T_Material_Freezers
       ON ML.Freezer_Tag = T_Material_Freezers.Freezer_Tag
WHERE ML.status = 'active'

GO
