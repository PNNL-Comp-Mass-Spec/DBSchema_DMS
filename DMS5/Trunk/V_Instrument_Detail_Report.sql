/****** Object:  View [dbo].[V_Instrument_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Detail_Report]
AS
SELECT InstName.Instrument_ID AS ID,
       InstName.IN_name AS Name,
       SPath.SP_vol_name_client + SPath.SP_path AS [Assigned Storage],
       S.Source AS [Assigned Source],
       AP.AP_archive_path AS [Assigned Archive Path],
       AP.AP_network_share_path AS [Archive Share Path],
       InstName.IN_Description AS Description,
       InstName.IN_class AS Class,
       InstName.IN_Group AS [Instrument Group],
       InstName.IN_Room_Number AS Room,
       InstName.IN_capture_method AS Capture,
       InstName.IN_status AS Status,
       InstName.IN_usage AS USAGE,
       InstName.IN_operations_role AS [Ops Role],
       dbo.[GetInstrumentDatasetTypeList](InstName.Instrument_ID) AS [Allowed Dataset Types],
       InstName.IN_Created AS Created,
       CASE
           WHEN ISNULL(InstName.Auto_Define_Storage_Path, 0) = 0 THEN 'No'
           ELSE 'Yes'
       END AS [Auto Define Storage],
       Auto_SP_Vol_Name_Client + Auto_SP_Path_Root AS [Auto Defined Storage Path Root],
       Auto_SP_Vol_Name_Server + Auto_SP_Path_Root AS [Auto Defined Storage Path On Server],
       Auto_SP_Archive_Server_Name + Auto_SP_Archive_Path_Root AS [Auto Defined Archive Path Root],
       Auto_SP_Archive_Share_Path_Root AS [Auto Defined Archive Share Path Root]
FROM dbo.T_Instrument_Name InstName
     INNER JOIN dbo.t_storage_path SPath
       ON InstName.IN_storage_path_ID = SPath.SP_path_ID
     INNER JOIN ( SELECT SP_path_ID,
                         SP_vol_name_server + SP_path AS Source
                  FROM t_storage_path ) S
       ON S.SP_path_ID = InstName.IN_source_path_ID
     LEFT OUTER JOIN T_Archive_Path AP
       ON AP.AP_instrument_name_ID = InstName.Instrument_ID AND
          AP.AP_Function = 'active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
