/****** Object:  View [dbo].[V_Instrument_Info_LCMSNet] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Info_LCMSNet] AS 
SELECT TIN.IN_name AS Instrument,
	   TIN.IN_name + CASE WHEN IN_usage = '' THEN '' ELSE + ' ' + IN_usage END AS NameAndUsage,
       TIN.IN_status as Status,
	   TP.SP_machine_name AS HostName,
       TP.SP_vol_name_server AS ServerPath,
       TP.SP_path AS SharePath,
       TIN.IN_capture_method AS CaptureMethod
FROM T_Instrument_Name AS TIN
     INNER JOIN t_storage_path AS TP
       ON TIN.IN_source_path_ID = TP.SP_path_ID
WHERE (NOT (TIN.IN_name LIKE 'SW_%')) AND (TIN.IN_status = 'active') AND (TIN.IN_operations_role <> 'QC')



GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Info_LCMSNet] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Info_LCMSNet] TO [PNL\D3M580] AS [dbo]
GO
