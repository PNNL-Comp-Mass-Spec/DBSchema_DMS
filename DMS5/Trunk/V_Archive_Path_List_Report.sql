/****** Object:  View [dbo].[V_Archive_Path_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Archive_Path_List_Report
AS
SELECT TAP.AP_Path_ID AS [Path ID], TIN.IN_name AS [Instrument Name], TAP.AP_archive_path AS [Archive Path], 
       TAP.AP_Server_Name AS [Archive Server],  TAP.AP_Function AS [Archive Path Status],
       TIN.IN_Description AS Description
FROM   T_Instrument_Name TIN INNER JOIN
       T_Archive_Path TAP ON TIN.Instrument_ID = TAP.AP_Instrument_Name_ID

GO
GRANT SELECT ON [dbo].[V_Archive_Path_List_Report] TO [DMS_SP_User]
GO
