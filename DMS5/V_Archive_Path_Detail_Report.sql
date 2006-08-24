/****** Object:  View [dbo].[V_Archive_Path_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Archive_Path_Detail_Report
AS
SELECT TAP.AP_Path_ID AS ID, TAP.AP_archive_path AS [Archive Path], 
       TAP.AP_Server_Name AS [Archive Server], TIN.IN_Name AS [Instrument Name], 
       TAP.Note AS Note, TAP.AP_Function AS [Status] 
FROM   T_Archive_Path TAP INNER JOIN T_Instrument_Name TIN ON TAP.AP_Instrument_Name_ID = TIN.Instrument_ID

GO
