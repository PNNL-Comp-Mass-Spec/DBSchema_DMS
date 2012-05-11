/****** Object:  View [dbo].[V_DMS_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_DMS_Archive_Path
AS
SELECT AP_Server_Name AS Archive_Server,
       AP_archive_path AS Archive_Path,
       AP_network_share_path AS Archive_Network_Share_Path,
       AP_path_ID
FROM S_DMS_T_Archive_Path AS TAP

GO
