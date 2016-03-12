/****** Object:  View [dbo].[V_Dataset_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Archive_Path]
AS
SELECT DA.AS_Dataset_ID AS Dataset_ID,
       AP.AP_network_share_path AS Archive_Path,
       DA.AS_instrument_data_purged AS Instrument_Data_Purged,
       AP.AP_archive_URL AS Archive_URL
FROM dbo.T_Archive_Path AP
     INNER JOIN dbo.T_Dataset_Archive DA
       ON AP.AP_path_ID = DA.AS_storage_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Archive_Path] TO [PNL\D3M578] AS [dbo]
GO
