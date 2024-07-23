/****** Object:  View [dbo].[V_Storage_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Storage_Summary]
AS
SELECT SLP.vol_client AS VolClient,
       SLP.storage_path,
       SLP.vol_server AS VolServer,
       InstGroup.IN_Group AS InstGroup,
       InstName.IN_name AS Instrument,
       SLP.Datasets,
       IsNull(SUM(CONVERT(decimal(9, 2), DS.File_Size_Bytes / 1024.0 / 1024.0 / 1024.0)), 0) AS File_Size_GB,
       MAX(DS.DS_created) AS Created_Max
FROM T_Instrument_Name InstName
     INNER JOIN T_Instrument_Group InstGroup
       ON InstName.IN_Group = InstGroup.IN_Group
     INNER JOIN V_Storage_List_Report SLP
       ON InstName.IN_name = SLP.Instrument
     INNER JOIN dbo.T_Dataset DS
       ON SLP.ID = DS.DS_storage_path_ID
WHERE SLP.storage_path_function <> 'inbox' AND
      SLP.Datasets > 0
GROUP BY SLP.vol_client, InstGroup.IN_Group, SLP.Datasets, SLP.storage_path, SLP.vol_server, InstName.IN_name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Summary] TO [DDL_Viewer] AS [dbo]
GO
