/****** Object:  View [dbo].[V_Instrument_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_List_Export]
AS	
SELECT Inst.Instrument_ID AS ID,
       Inst.IN_name AS Name,
       Inst.IN_Description AS Description,
       Inst.IN_Room_Number AS Room,
       Inst.IN_usage AS Usage,
       Inst.IN_operations_role AS OpsRole,
       Inst.IN_status AS Status,
       Inst.IN_class AS Class,
       Inst.IN_capture_method AS Capture,
       InstClass.raw_data_type AS RawDataType,
       SrcPath.Source_Path AS SourcePath,
       StoragePath.Storage_Path AS StoragePath,
       InstClass.is_purgable AS IsPurgable,
       InstClass.requires_preparation AS RequiresPreparation,
       Inst.Percent_EMSL_Owned AS PercentEMSLOwned
FROM dbo.T_Instrument_Name Inst
     INNER JOIN ( SELECT SP_path_ID,
                         SP_vol_name_client + SP_path AS Storage_Path
                  FROM dbo.t_storage_path ) StoragePath
       ON Inst.IN_storage_path_ID = StoragePath.SP_path_ID
     INNER JOIN ( SELECT SP_path_ID,
                         SP_vol_name_server + SP_path AS Source_Path
                  FROM t_storage_path ) SrcPath
       ON SrcPath.SP_path_ID = Inst.IN_source_path_ID
     INNER JOIN dbo.T_Instrument_Class InstClass
       ON Inst.IN_class = InstClass.IN_class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_List_Export] TO [DDL_Viewer] AS [dbo]
GO
