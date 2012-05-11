/****** Object:  View [dbo].[V_Storage_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_List_Report]
AS
SELECT SPath.SP_path_ID AS ID,
       SPath.SP_path AS [Path],
       SPath.SP_vol_name_client AS [Vol Client],
       SPath.SP_vol_name_server AS [Vol Server],
       SPath.SP_function AS [Function],
       SPath.SP_instrument_name AS Instrument,
       COUNT(DS.Dataset_ID) AS Datasets,
       SPath.SP_description AS Description,
       SPath.SP_Created as Created
FROM dbo.t_storage_path SPath
     LEFT OUTER JOIN dbo.T_Dataset DS
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
GROUP BY SPath.SP_path_ID, SPath.SP_path, SPath.SP_vol_name_client,
         SPath.SP_vol_name_server, SPath.SP_function,
         SPath.SP_instrument_name, SPath.SP_description, SPath.SP_Created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_List_Report] TO [PNL\D3M580] AS [dbo]
GO
