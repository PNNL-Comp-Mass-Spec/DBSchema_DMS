/****** Object:  View [dbo].[V_Assigned_Storage_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW dbo.V_Assigned_Storage_Report
AS
SELECT T_Instrument_Name.IN_name AS Instrument, 
   v_raw_storage.SP_vol_name_client + v_raw_storage.SP_path AS
    [Storage Path], 
   v_source.SP_vol_name_server + v_source.SP_path AS [Source Path],
    T_Instrument_Name.IN_capture_method AS [Capture Method]
FROM T_Instrument_Name INNER JOIN
   v_source ON 
   T_Instrument_Name.IN_source_path_ID = v_source.SP_path_ID INNER
    JOIN
   v_raw_storage ON 
   T_Instrument_Name.IN_storage_path_ID = v_raw_storage.SP_path_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Storage_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Storage_Report] TO [PNL\D3M580] AS [dbo]
GO
