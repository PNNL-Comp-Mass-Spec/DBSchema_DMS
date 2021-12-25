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
       InstName.IN_usage AS [Usage],
       InstName.IN_operations_role AS [Ops Role],
       TrackingYesNo.Description As [Track Usage When Inactive],
       Case When InstName.IN_status = 'active' Then ScanSourceYesNo.Description Else 'No (not active)' End AS [Scan Source],
       InstGroup.Allocation_Tag AS [Allocation Tag],
       InstName.Percent_EMSL_Owned AS [Percent EMSL Owned],
       dbo.GetInstrumentDatasetTypeList(InstName.Instrument_ID) AS [Allowed Dataset Types],
       InstName.IN_Created AS Created,
       DefineStorageYesNo.Description AS [Auto Define Storage],
       InstName.Auto_SP_Vol_Name_Client + InstName.Auto_SP_Path_Root AS [Auto Defined Storage Path Root],
       InstName.Auto_SP_Vol_Name_Server + InstName.Auto_SP_Path_Root AS [Auto Defined Storage Path On Server],
       InstName.Auto_SP_URL_Domain AS [Auto Defined URL Domain],
       InstName.Auto_SP_Archive_Server_Name + InstName.Auto_SP_Archive_Path_Root AS [Auto Defined Archive Path Root],
       InstName.Auto_SP_Archive_Share_Path_Root AS [Auto Defined Archive Share Path Root],
       EUSMapping.EUS_Instrument_ID AS [EUS Instrument ID],
       EUSMapping.EUS_Display_Name AS [EUS Display Name],
       EUSMapping.EUS_Instrument_Name AS [EUS Instrument Name],
       EUSMapping.Local_Instrument_Name AS [Local Instrument Name],
       Case When InstTracking.Reporting Like '%E%' Then 'EUS Primary Instrument'
            When InstTracking.Reporting Like '%P%' Then 'Production operations role'
            When InstTracking.Reporting Like '%T%' Then 'IN_Tracking flag enabled'
            Else ''
       End As [Usage Tracking Status],
       InstName.Default_Purge_Policy AS [Default Purge Policy],
       InstName.Default_Purge_Priority AS [Default Purge Priority],
       InstName.Storage_Purge_Holdoff_Months AS [Storage Purge Holdoff Months]
FROM T_Instrument_Name InstName
     LEFT OUTER JOIN T_Storage_Path SPath
       ON InstName.IN_storage_path_ID = SPath.SP_path_ID
     INNER JOIN ( SELECT SP_path_ID,
                         SP_vol_name_server + SP_path AS Source
                  FROM T_Storage_Path ) S
       ON S.SP_path_ID = InstName.IN_source_path_ID
     INNER JOIN T_YesNo DefineStorageYesNo
       ON InstName.Auto_Define_Storage_Path = DefineStorageYesNo.Flag
     INNER JOIN T_YesNo ScanSourceYesNo
       ON InstName.Scan_SourceDir = ScanSourceYesNo.Flag
     INNER JOIN dbo.T_Instrument_Group InstGroup
       ON InstName.IN_Group = InstGroup.IN_Group
     INNER JOIN T_YesNo TrackingYesNo
       ON InstName.IN_Tracking = TrackingYesNo.Flag
     LEFT OUTER JOIN T_Archive_Path AP
       ON AP.AP_instrument_name_ID = InstName.Instrument_ID AND
          AP.AP_Function = 'active'
     LEFT OUTER JOIN ( SELECT InstName.Instrument_ID,
                              EMSLInst.EUS_Instrument_ID,
                              EMSLInst.EUS_Display_Name,
                              EMSLInst.EUS_Instrument_Name,
                              EMSLInst.Local_Instrument_Name
                       FROM T_EMSL_DMS_Instrument_Mapping InstMapping
                            INNER JOIN T_EMSL_Instruments EMSLInst
                              ON InstMapping.EUS_Instrument_ID = EMSLInst.EUS_Instrument_ID
                            INNER JOIN T_Instrument_Name InstName
                              ON InstMapping.DMS_Instrument_ID = InstName.Instrument_ID ) AS 
                       EUSMapping
       ON InstName.Instrument_ID = EUSMapping.Instrument_ID
     LEFT OUTER JOIN V_Instrument_Tracked InstTracking
       ON InstName.IN_name = InstTracking.[Name]

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
