/****** Object:  View [dbo].[V_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_List_Report]
AS
SELECT InstName.Instrument_ID AS ID,
       InstName.IN_name AS Name,
       InstName.IN_Description AS Description,
       InstName.IN_class AS Class,
       InstName.IN_group AS [Group],
       InstName.IN_status AS Status,
       InstName.IN_usage AS [Usage],
       InstName.IN_operations_role AS [Ops Role],
       InstGroup.Allocation_Tag AS Allocation_Tag,
       InstName.Percent_EMSL_Owned AS [Percent EMSL Owned],
       InstName.IN_capture_method AS Capture,
       InstName.IN_Room_Number AS Room,
       SPath.SP_vol_name_client + SPath.SP_path AS [Assigned Storage],
       S.Source AS [Assigned Source],
       T_YesNo.Description AS [Auto Define Storage],
       dbo.[GetInstrumentDatasetTypeList](InstName.Instrument_ID) AS [Allowed Dataset Types],
       InstName.IN_Created AS Created,
       EUSMapping.EUS_Instrument_ID,
       EUSMapping.EUS_Display_Name,
       EUSMapping.EUS_Instrument_Name,
	   EUSMapping.Local_Instrument_Name
FROM dbo.T_Instrument_Name InstName
     INNER JOIN T_YesNo
       ON InstName.Auto_Define_Storage_Path = T_YesNo.Flag
     INNER JOIN dbo.T_Instrument_Group InstGroup
       ON InstName.IN_Group = InstGroup.IN_Group
     LEFT OUTER JOIN dbo.t_storage_path SPath
       ON InstName.IN_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN ( SELECT SP_path_ID,
                              SP_vol_name_server + SP_path AS Source
                       FROM t_storage_path ) S
       ON S.SP_path_ID = InstName.IN_source_path_ID
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
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_List_Report] TO [PNL\D3M578] AS [dbo]
GO
