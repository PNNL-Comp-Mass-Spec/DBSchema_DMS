/****** Object:  View [dbo].[V_Material_Containers_Active_Export_RFID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Containers_Active_Export_RFID]
AS
SELECT MC.Tag AS container,
       MC.Comment AS comment,
       CASE
         WHEN C.Campaign_Num IS NULL OR C.Campaign_Num = 'Not_Set' THEN
           ''
         ELSE
           C.Campaign_Num
       END AS campaign,
       MC.Created AS created,
       --MC.Status AS status,
       MC.Researcher AS researcher,
       MC.ID AS id,
       MC.RFID_Hex_ID AS hex_id
FROM T_Material_Containers MC
     LEFT OUTER JOIN T_Campaign C
       ON MC.Campaign_ID = C.Campaign_ID
WHERE status = 'Active'

GO
