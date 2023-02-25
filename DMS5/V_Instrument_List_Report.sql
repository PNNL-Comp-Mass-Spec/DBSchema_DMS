/****** Object:  View [dbo].[V_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_List_Report]
AS
SELECT InstName.Instrument_ID AS id,
       InstName.IN_name AS name,
       InstName.IN_Description AS description,
       InstName.IN_class AS class,
       InstName.IN_group AS [group],
       InstName.IN_status AS status,
       InstName.IN_usage AS usage,
       InstName.IN_operations_role AS ops_role,
       Case When InstName.IN_status = 'active' Then ScanSourceYesNo.Description Else 'No' End AS scan_source,
       InstGroup.Allocation_Tag AS allocation_tag,
       InstName.Percent_EMSL_Owned AS percent_emsl_owned,
       InstName.IN_capture_method AS capture,
       InstName.IN_Room_Number AS room,
       SPath.SP_vol_name_client + SPath.SP_path AS assigned_storage,
       S.Source AS assigned_source,
       DefineStorageYesNo.Description AS auto_define_storage,
       InstName.Auto_SP_Vol_Name_Client + InstName.Auto_SP_Path_Root AS auto_storage_path,
       dbo.get_instrument_dataset_type_list(InstName.Instrument_ID) AS allowed_dataset_types,
       InstName.IN_Created AS created,
       EUSMapping.EUS_Instrument_ID AS eus_instrument_id,
       EUSMapping.EUS_Display_Name AS eus_display_name,
       EUSMapping.EUS_Instrument_Name AS eus_instrument_name,
       EUSMapping.Local_Instrument_Name AS local_instrument_name,
       Case When InstTracking.Reporting Like '%E%' Then 'EUS Primary Instrument'
            When InstTracking.Reporting Like '%P%' Then 'Production operations role'
            When InstTracking.Reporting Like '%T%' Then 'IN_Tracking flag enabled'
            Else ''
       End As usage_tracking_status,
       TrackingYesNo.Description AS track_when_inactive,
       InstName.Storage_Purge_Holdoff_Months AS storage_purge_holdoff_months
FROM dbo.T_Instrument_Name InstName
     INNER JOIN T_YesNo DefineStorageYesNo
       ON InstName.Auto_Define_Storage_Path = DefineStorageYesNo.Flag
     INNER JOIN T_YesNo ScanSourceYesNo
       ON InstName.Scan_SourceDir = ScanSourceYesNo.Flag
     INNER JOIN dbo.T_Instrument_Group InstGroup
       ON InstName.IN_Group = InstGroup.IN_Group
     INNER JOIN dbo.T_YesNo TrackingYesNo
       ON InstName.IN_Tracking = TrackingYesNo.Flag
     LEFT OUTER JOIN dbo.t_storage_path SPath
       ON InstName.IN_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN ( SELECT SP_path_ID,
                              SP_vol_name_server + SP_path AS Source
                       FROM t_storage_path ) S
       ON S.SP_path_ID = InstName.IN_source_path_ID
     LEFT OUTER JOIN ( SELECT InstName.Instrument_ID,
                              EMSLInst.EUS_Instrument_ID,
                              EMSLInst.EUS_Display_Name,
                              EMSLInst.EUS_Instrument_Name,
                              EMSLInst.Local_Instrument_Name
                       FROM T_EMSL_DMS_Instrument_Mapping InstMapping
                            INNER JOIN T_EMSL_Instruments EMSLInst
                              ON InstMapping.EUS_Instrument_ID = EMSLInst.EUS_Instrument_ID
                            INNER JOIN T_Instrument_Name InstName
                              ON InstMapping.DMS_Instrument_ID = InstName.Instrument_ID )
AS
                       EUSMapping
       ON InstName.Instrument_ID = EUSMapping.Instrument_ID
     LEFT OUTER JOIN V_Instrument_Tracked InstTracking
       ON InstName.IN_name = InstTracking.Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_List_Report] TO [DDL_Viewer] AS [dbo]
GO
