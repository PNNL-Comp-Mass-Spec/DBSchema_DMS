/****** Object:  View [dbo].[V_Archive_Path_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Path_List_Report]
AS
SELECT TAP.AP_path_ID AS [Path ID], 
    TIN.IN_name AS [Instrument Name], 
    TAP.AP_archive_path AS [Archive Path], 
    TAP.AP_Server_Name AS [Archive Server], 
    TAP.AP_Function AS [Archive Path Status], 
    COUNT(DA.AS_Dataset_ID) AS Datasets,
    TIN.IN_Description AS Description, 
    TAP.AP_network_share_path AS [Archive Share Path], 
    TAP.AP_archive_URL AS [Archive URL], 
    TAP.AP_Created as Created
FROM T_Instrument_Name TIN INNER JOIN
    T_Archive_Path TAP ON 
    TIN.Instrument_ID = TAP.AP_instrument_name_ID LEFT OUTER JOIN
    T_Dataset_Archive DA ON 
    TAP.AP_path_ID = DA.AS_storage_path_ID
GROUP BY TAP.AP_path_ID, TIN.IN_name, TAP.AP_archive_path, 
    TAP.AP_Server_Name, TAP.AP_Function, TIN.IN_Description, 
    TAP.AP_network_share_path, TAP.AP_archive_URL, TAP.AP_Created


GO
GRANT SELECT ON [dbo].[V_Archive_Path_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_List_Report] TO [PNL\D3M580] AS [dbo]
GO
