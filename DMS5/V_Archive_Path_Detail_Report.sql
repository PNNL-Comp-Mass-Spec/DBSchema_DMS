/****** Object:  View [dbo].[V_Archive_Path_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Path_Detail_Report]
AS
SELECT TAP.AP_path_ID AS id,
       TAP.AP_archive_path AS archive_path,
       TAP.AP_Server_Name AS archive_server,
       TAP.AP_network_share_path AS network_share_path,
       TIN.IN_name AS instrument_name,
       TAP.note,
       TAP.AP_Function AS status,
       TAP.AP_archive_URL AS archive_url
FROM dbo.T_Archive_Path AS TAP
     INNER JOIN dbo.T_Instrument_Name AS TIN
       ON TAP.AP_instrument_name_ID = TIN.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
