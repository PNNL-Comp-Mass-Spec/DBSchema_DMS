/****** Object:  View [dbo].[V_Instrument_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Detail_Report]
AS
SELECT InstName.Instrument_ID AS ID,
       InstName.IN_name AS Name,
       SPath.SP_vol_name_client + SPath.SP_path AS [Assigned Storage],
       S.Source AS [Assigned Source],
       AP.AP_archive_path AS [Assigned Archive Path],
       AP.AP_network_share_path AS [Archive Share Path],
       InstName.IN_Description AS Description,
       InstName.IN_class AS Class,
       InstName.IN_Group AS [Instrument Group],
       InstName.IN_Room_Number AS Room,
       InstName.IN_capture_method AS Capture,
       InstName.IN_status AS Status,
       InstName.IN_usage AS [Usage],
       InstName.IN_operations_role AS [Ops Role],
       InstName.Percent_EMSL_Owned AS [Percent EMSL Owned],
       dbo.GetInstrumentDatasetTypeList(InstName.Instrument_ID) AS [Allowed Dataset Types],
       InstName.IN_Created AS Created,
       T_YesNo.Description AS [Auto Define Storage],
       InstName.Auto_SP_Vol_Name_Client + InstName.Auto_SP_Path_Root AS [Auto Defined Storage Path Root],
       InstName.Auto_SP_Vol_Name_Server + InstName.Auto_SP_Path_Root AS [Auto Defined Storage Path On Server],
       InstName.Auto_SP_Archive_Server_Name + InstName.Auto_SP_Archive_Path_Root AS [Auto Defined Archive Path Root],
       InstName.Auto_SP_Archive_Share_Path_Root AS [Auto Defined Archive Share Path Root],
       EUSMapping.EUS_Instrument_ID,
       EUSMapping.EUS_Display_Name,
       EUSMapping.EUS_Instrument_Name,
	   EUSMapping.Local_Instrument_Name
FROM T_Instrument_Name InstName
     INNER JOIN T_Storage_Path SPath
       ON InstName.IN_storage_path_ID = SPath.SP_path_ID
     INNER JOIN ( SELECT SP_path_ID,
                         SP_vol_name_server + SP_path AS Source
                  FROM T_Storage_Path ) S
       ON S.SP_path_ID = InstName.IN_source_path_ID
     INNER JOIN T_YesNo
       ON InstName.Auto_Define_Storage_Path = T_YesNo.Flag
     LEFT OUTER JOIN T_Archive_Path AP
       ON AP.AP_instrument_name_ID = InstName.Instrument_ID AND
          AP.AP_Function = 'active'
     LEFT OUTER JOIN ( SELECT InstName.Instrument_ID,
                              EMSLInst.EUS_Instrument_ID,
                              EMSLInst.EUS_Display_Name,
                              EMSLInst.EUS_Instrument_Name,
							  EMSLInst.Local_Instrument_Name
                       FROM T_EMSL_DMS_Instrument_Mapping InstMapping
                            INNER JOIN T_EMSL_Instruments EMSLInst
                              ON InstMapping.EUS_Instrument_ID = EMSLInst.EUS_Instrument_ID
                            INNER JOIN T_Instrument_Name InstName
                              ON InstMapping.DMS_Instrument_ID = InstName.Instrument_ID ) AS 
                       EUSMapping
       ON InstName.Instrument_ID = EUSMapping.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
