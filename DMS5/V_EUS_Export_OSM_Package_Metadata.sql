/****** Object:  View [dbo].[V_EUS_Export_OSM_Package_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_EUS_Export_OSM_Package_Metadata]
AS
SELECT TOSM.ID,
       TOSM.Name,
       TOSM.Package_Type AS [Type],
       TOSM.Description,
       TOSM.Keywords,
       TOSM.Comment AS [Comment],
       TONR.U_Name AS Owner,
       ISNULL(TOSM.Owner, '') as Owner_PRN,
       TOSM.Created,
       TOSM.Last_Modified AS Modified,
       TOSM.State,
       '/aurora/dmsarch/dms_attachments/osm_package/spread/' + Convert(varchar(12), TOSM.ID) AS Archive_Path
FROM DMS_Data_Package.dbo.T_OSM_Package AS TOSM
     LEFT OUTER JOIN T_Users AS TONR
       ON TONR.U_PRN = TOSM.Owner


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_OSM_Package_Metadata] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_OSM_Package_Metadata] TO [PNL\D3M580] AS [dbo]
GO
