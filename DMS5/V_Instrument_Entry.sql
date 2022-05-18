/****** Object:  View [dbo].[V_Instrument_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Entry]
AS
SELECT Instrument_ID AS id,
       IN_name AS instrument_name,
       IN_Description AS description,
       IN_class AS instrument_class,
       IN_group AS instrument_group,
       IN_Room_Number AS room_number,
       IN_capture_method AS capture_method,
       RTRIM(IN_status) AS status,
       IN_usage AS [usage],
       IN_operations_role AS operations_role,
       CASE
           WHEN ISNULL(IN_Tracking, 0) = 0 THEN 'N'
           ELSE 'Y'
       END AS track_usage_when_inactive,
       CASE
           WHEN ISNULL(Scan_SourceDir, 0) = 0 THEN 'N'
           ELSE 'Y'
       END AS scan_source_dir,
       Percent_EMSL_Owned AS percent_emsl_owned,
       IN_source_path_ID AS source_path_id,
       IN_storage_path_ID AS storage_path_id,
       CASE
           WHEN ISNULL(Auto_Define_Storage_Path, 0) = 0 THEN 'N'
           ELSE 'Y'
       END AS auto_define_storage_path,
       Auto_SP_Vol_Name_Client AS auto_sp_vol_name_client,
       Auto_SP_Vol_Name_Server AS auto_sp_vol_name_server,
       Auto_SP_Path_Root AS auto_sp_path_root,
       Auto_SP_URL_Domain AS auto_sp_url_domain,
       Auto_SP_Archive_Server_Name AS auto_sp_archive_server_name,
       Auto_SP_Archive_Path_Root AS auto_sp_archive_path_root,
       Auto_SP_Archive_Share_Path_Root AS auto_sp_archive_share_path_root
FROM dbo.T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Entry] TO [DDL_Viewer] AS [dbo]
GO
