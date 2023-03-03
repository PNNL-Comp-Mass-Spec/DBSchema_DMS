/****** Object:  View [dbo].[V_Archive_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Check_Report]
AS
SELECT DS.Dataset_ID AS dataset_id, DS.Dataset_Num AS dataset, DASN.archive_state, DA.AS_state_Last_Affected AS last_affected,
       InstName.IN_name AS instrument, SP.SP_machine_name AS storage_server, AP.AP_archive_path AS archive_path,
       DA.AS_archive_processor AS archive_processor, DA.AS_update_processor AS update_processor,
       DA.AS_verification_processor AS verification_processor
FROM dbo.T_Dataset_Archive AS DA INNER JOIN
     dbo.T_Dataset_Archive_State_Name AS DASN ON DA.AS_state_ID = DASN.archive_state_id INNER JOIN
     dbo.T_Dataset AS DS ON DA.AS_Dataset_ID = DS.Dataset_ID INNER JOIN
     dbo.T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID INNER JOIN
     dbo.T_Storage_Path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID INNER JOIN
     dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE (DA.AS_state_ID NOT IN (3, 4, 9, 10, 14, 15))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Check_Report] TO [DDL_Viewer] AS [dbo]
GO
