/****** Object:  View [dbo].[V_Assigned_Archive_Storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Assigned_Archive_Storage]
AS
SELECT dbo.T_Instrument_Name.IN_name AS instrument_name,
       dbo.T_Archive_Path.AP_archive_path AS archive_path,
       dbo.T_Archive_Path.AP_Server_Name AS archive_server,
       dbo.T_Archive_Path.AP_path_ID AS archive_path_id
FROM dbo.T_Archive_Path INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Archive_Path.AP_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE     (dbo.T_Archive_Path.AP_Function = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Archive_Storage] TO [DDL_Viewer] AS [dbo]
GO
