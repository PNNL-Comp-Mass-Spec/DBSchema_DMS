/****** Object:  View [dbo].[V_DMS_PrepLC_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_DMS_PrepLC_Job_Parameters] AS
SELECT TPR.ID,
       TPR.Instrument,
       CASE WHEN TSrc.SP_path_ID IS NULL THEN 'ProteomicsData\' ELSE TSrc.SP_path END AS sourcePath,
       CASE WHEN TSrc.SP_path_ID IS NULL THEN '\\Not_Defined_see_T_Prep_Instrument_Storage.bionet\' ELSE TSrc.SP_vol_name_server END AS sourceVol,
       CASE WHEN TSrc.SP_path_ID IS NULL THEN 0 ELSE TSrc.SP_path_ID END As SP_path_ID,
       CASE WHEN TStor.SP_path_ID IS NULL THEN 0 ELSE TStor.SP_path_ID END AS Storage_Path_ID,
       CASE WHEN TStor.SP_path_ID IS NULL THEN 'Not_Defined_see_T_Prep_Instrument_Storage' Else TStor.SP_machine_name END AS Storage_Server_Name,
       CASE WHEN TStor.SP_path_ID IS NULL THEN '\\Not_Defined_see_T_Prep_Instrument_Storage\' ELSE TStor.SP_vol_name_server END AS Storage_Vol,
       CASE WHEN TStor.SP_path_ID IS NULL THEN 'Sample_Prep_Repository\HPLC_Run_Seq\' + TPR.Instrument + '\' Else TStor.SP_path END AS Storage_Path,
       CASE WHEN TStor.SP_path_ID IS NULL THEN '\\Not_Defined_see_T_Prep_Instrument_Storage\' ELSE TStor.SP_vol_name_client END AS Storage_Vol_External,
       '' AS SourceFolderName,
       '' AS Comment,
       '' AS Job,
       TPI.Capture_Method
FROM S_DMS_T_Prep_LC_Run AS TPR
     INNER JOIN S_DMS_T_Prep_Instruments AS TPI
       ON TPI.Name = TPR.Instrument
     LEFT OUTER JOIN S_DMS_T_Prep_Instrument_Storage AS TSrc
       ON TPR.Instrument = TSrc.SP_instrument_name AND
          TSrc.SP_function = 'inbox'
     LEFT OUTER JOIN S_DMS_T_Prep_Instrument_Storage AS TStor
       ON TPR.Instrument = TStor.SP_instrument_name AND
          TStor.SP_function = 'raw-storage'


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PrepLC_Job_Parameters] TO [DDL_Viewer] AS [dbo]
GO
