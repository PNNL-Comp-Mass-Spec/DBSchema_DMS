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
       TIN.IN_Description AS Description,
       TAP.AP_network_share_path AS [Archive Share Path],
       TAP.AP_archive_URL AS [Archive URL]
FROM dbo.T_Instrument_Name AS TIN
     INNER JOIN dbo.T_Archive_Path AS TAP
       ON TIN.Instrument_ID = TAP.AP_instrument_name_ID


GO
GRANT SELECT ON [dbo].[V_Archive_Path_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_List_Report] TO [PNL\D3M580] AS [dbo]
GO
