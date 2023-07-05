/****** Object:  View [dbo].[V_Instrument_List_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_List_Export]
AS
SELECT Inst.Instrument_ID AS id,
       Inst.IN_name AS name,
       Inst.IN_Description AS description,
       Inst.IN_Room_Number AS room,
       Inst.IN_usage AS usage,
       Inst.IN_operations_role AS ops_role,
       Inst.IN_status AS status,
       Inst.IN_class AS class,
       Inst.IN_Group AS instrument_group,
       Inst.IN_capture_method AS capture,
       InstClass.raw_data_type AS raw_data_type,
       SrcPath.Source_Path AS source_path,
       StoragePath.Storage_Path AS storage_path,
       InstClass.is_purgable AS is_purgeable,
       InstClass.requires_preparation AS requires_preparation,
       Inst.Percent_EMSL_Owned AS percent_emsl_owned,
       -- Legacy column names
       Inst.IN_operations_role AS OpsRole,
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
