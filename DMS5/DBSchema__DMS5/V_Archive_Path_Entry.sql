/****** Object:  View [dbo].[V_Archive_Path_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Archive_Path_Entry
AS
SELECT TAP.AP_Path_ID, TAP.AP_archive_path, 
       TAP.AP_Server_Name, TIN.IN_Name AS AP_Instrument_Name, TAP.Note, TAP.AP_Function 
FROM   T_Archive_Path TAP INNER JOIN T_Instrument_Name TIN ON TAP.AP_Instrument_Name_ID = TIN.Instrument_ID

GO
