/****** Object:  View [dbo].[V_GetInstrumentCaptureParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetInstrumentCaptureParameters
AS
SELECT     dbo.T_Instrument_Name.Instrument_ID, dbo.T_Instrument_Name.IN_name, dbo.T_Instrument_Name.IN_Max_Simultaneous_Captures, 
                      dbo.T_Instrument_Name.IN_Max_Queued_Datasets, dbo.T_Instrument_Name.IN_Capture_Exclusion_Window, 
                      dbo.T_Instrument_Name.IN_Capture_Log_Level, dbo.T_Instrument_Name.IN_capture_method, dbo.T_Instrument_Class.is_purgable, 
                      dbo.T_Instrument_Class.raw_data_type, dbo.T_Instrument_Class.requires_preparation, StoragePath.SP_machine_name, 
                      SourcePath.SP_vol_name_server AS sourceVol, SourcePath.SP_path AS sourcePath
FROM         dbo.T_Instrument_Name INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Class.IN_class = dbo.T_Instrument_Name.IN_class INNER JOIN
                      dbo.t_storage_path AS StoragePath ON dbo.T_Instrument_Name.IN_storage_path_ID = StoragePath.SP_path_ID INNER JOIN
                      dbo.t_storage_path AS SourcePath ON dbo.T_Instrument_Name.IN_source_path_ID = SourcePath.SP_path_ID

GO
