/****** Object:  View [dbo].[V_DMS_PrepLC_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_DMS_PrepLC_Job_Parameters AS
SELECT TPR.ID,
       TPR.Instrument,
       TSrc.SP_path AS sourcePath,
       TSrc.SP_vol_name_server AS sourceVol,
       TSrc.SP_path_ID,
       CASE WHEN TStor.SP_path_ID IS NULL THEN TStorA.SP_path_ID
            ELSE TStor.SP_path_ID
       END AS Storage_Path_ID,
       CASE WHEN TStor.SP_path_ID IS NULL THEN TStorA.SP_machine_name
            ELSE TStor.SP_machine_name
       END AS Storage_Server_Name,
       CASE WHEN TStor.SP_path_ID IS NULL THEN TStorA.SP_vol_name_server
            ELSE TStor.SP_vol_name_server
       END AS Storage_Vol,
       CASE WHEN TStor.SP_path_ID IS NULL THEN TStorA.SP_path
            ELSE TStor.SP_path
       END AS Storage_Path,
       CASE WHEN TStor.SP_path_ID IS NULL THEN TStorA.SP_vol_name_client
            ELSE TStor.SP_vol_name_client
       END AS Storage_Vol_External,
       '' AS SourceFolderName,
       '' AS Comment,
       '' AS Job,
       TPI.Capture_Method
FROM S_DMS_T_Prep_LC_Run AS TPR
     INNER JOIN S_DMS_T_Prep_Instrument_Storage AS TSrc
       ON TPR.Instrument = TSrc.SP_instrument_name AND
          TSrc.SP_function = 'inbox'
     LEFT OUTER JOIN S_DMS_T_Prep_Instrument_Storage AS TStor
       ON TPR.Storage_Path = TStor.SP_path_ID
     INNER JOIN S_DMS_T_Prep_Instrument_Storage AS TStorA
       ON TPR.Instrument = TStorA.SP_instrument_name AND
          TStorA.SP_function = 'raw-storage'
     INNER JOIN S_DMS_T_Prep_Instruments AS TPI
       ON TPI.Name = TPR.Instrument

GO
