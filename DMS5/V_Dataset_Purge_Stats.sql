/****** Object:  View [dbo].[V_Dataset_Purge_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Purge_Stats
AS
SELECT TheYear,
       TheMonth,
       StoragePath,
       Instrument,
       Dataset_Count,
       Purged_Datasets,
       CONVERT(decimal(7, 2), Purged_Datasets / CONVERT(float, Dataset_Count) * 100) AS Percent_Purged
FROM ( SELECT YEAR(DS.DS_created) AS TheYear,
              MONTH(DS.DS_created) AS TheMonth,
              '\\' + SPath.SP_machine_name + '\' + SPath.SP_path AS StoragePath,
              InstName.IN_name AS Instrument,
              COUNT(*) AS Dataset_Count,
              SUM(DA.AS_instrument_data_purged) AS Purged_Datasets
       FROM dbo.T_Dataset DS
            INNER JOIN dbo.t_storage_path SPath
              ON DS.DS_storage_path_ID = SPath.SP_path_ID
            INNER JOIN dbo.T_Instrument_Name InstName
              ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            INNER JOIN dbo.T_Dataset_Archive DA
              ON DS.Dataset_ID = DA.AS_Dataset_ID
       GROUP BY InstName.IN_name, '\\' + SPath.SP_machine_name + '\' + SPath.SP_path, 
                                    YEAR(DS.DS_created), MONTH(DS.DS_created) ) LookupQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Purge_Stats] TO [DDL_Viewer] AS [dbo]
GO
