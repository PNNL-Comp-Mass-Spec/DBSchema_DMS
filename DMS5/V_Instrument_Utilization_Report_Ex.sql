/****** Object:  View [dbo].[V_Instrument_Utilization_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Utilization_Report_Ex]
AS
SELECT InstName.IN_name AS Instrument,
       DS.DS_instrument_name_ID AS Instrument_ID,
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       NULL AS Run_Start,
       DS.DS_created AS Run_Finish,
       dbo.T_Requested_Run.ID AS Request,
       dbo.T_Requested_Run.RDS_Requestor_PRN AS Requester,
       dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path + DS.DS_folder_name AS DatasetFolder
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.t_storage_path
       ON DS.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
     LEFT OUTER JOIN dbo.T_Requested_Run
       ON DS.Dataset_ID = dbo.T_Requested_Run.DatasetID
WHERE DS.DS_state_ID = 3

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Utilization_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
