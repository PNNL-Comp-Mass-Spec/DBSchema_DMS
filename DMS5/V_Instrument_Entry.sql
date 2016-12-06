/****** Object:  View [dbo].[V_Instrument_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Entry]
AS
SELECT Instrument_ID AS ID,
       IN_name AS InstrumentName,
       IN_Description AS Description,
       IN_class AS InstrumentClass,
       IN_group AS InstrumentGroup,
       IN_Room_Number AS RoomNumber,
       IN_capture_method AS CaptureMethod,
       RTRIM(IN_status) AS Status,
       IN_usage AS [Usage],
       IN_operations_role AS OperationsRole,
       Percent_EMSL_Owned AS PercentEMSLOwned,
       IN_source_path_ID AS SourcePathID,
       IN_storage_path_ID AS StoragePathID,
       CASE
           WHEN ISNULL(Auto_Define_Storage_Path, 0) = 0 THEN 'N'
           ELSE 'Y'
       END AS AutoDefineStoragePath,
       Auto_SP_Vol_Name_Client AS AutoSPVolNameClient,
       Auto_SP_Vol_Name_Server AS AutoSPVolNameServer,
       Auto_SP_Path_Root AS AutoSPPathRoot,
       Auto_SP_Archive_Server_Name AS AutoSPArchiveServerName,
       Auto_SP_Archive_Path_Root AS AutoSPArchivePathRoot,
       Auto_SP_Archive_Share_Path_Root AS AutoSPArchiveSharePathRoot
FROM dbo.T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Entry] TO [DDL_Viewer] AS [dbo]
GO
