/****** Object:  View [dbo].[V_Archive_Path_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Archive_Path_Entry
AS
SELECT TAP.AP_path_ID AS archive_path_id,
       TAP.AP_archive_path AS archive_path,
       TAP.AP_Server_Name AS server_name,
       TIN.IN_name AS instrument_name,
       TAP.note,
       TAP.AP_Function AS archive_path_function,
       TAP.AP_network_share_path AS network_share_path
FROM T_Archive_Path AS TAP
     INNER JOIN T_Instrument_Name AS TIN
       ON TAP.AP_instrument_name_ID = TIN.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_Entry] TO [DDL_Viewer] AS [dbo]
GO
