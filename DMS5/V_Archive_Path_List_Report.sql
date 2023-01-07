/****** Object:  View [dbo].[V_Archive_Path_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Path_List_Report]
AS
SELECT TAP.AP_path_ID AS path_id,
    TIN.IN_name AS instrument_name,
    TAP.AP_archive_path AS archive_path,
    TAP.AP_Server_Name As archive_server,
    TAP.AP_Function AS archive_path_status,
    COUNT(DA.AS_Dataset_ID) AS datasets,
    TIN.IN_Description AS description,
    TAP.AP_network_share_path AS archive_share_path,
    TAP.AP_archive_URL AS archive_url,
    TAP.AP_Created AS created
FROM T_Instrument_Name TIN INNER JOIN
    T_Archive_Path TAP ON
    TIN.Instrument_ID = TAP.AP_instrument_name_ID LEFT OUTER JOIN
    T_Dataset_Archive DA ON
    TAP.AP_path_ID = DA.AS_storage_path_ID
GROUP BY TAP.AP_path_ID, TIN.IN_name, TAP.AP_archive_path,
    TAP.AP_Server_Name, TAP.AP_Function, TIN.IN_Description,
    TAP.AP_network_share_path, TAP.AP_archive_URL, TAP.AP_Created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Archive_Path_List_Report] TO [DMS_SP_User] AS [dbo]
GO
