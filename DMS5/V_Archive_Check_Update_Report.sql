/****** Object:  View [dbo].[V_Archive_Check_Update_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Check_Update_Report
AS
SELECT DA.AS_Dataset_ID AS dataset_id, DS.Dataset_Num AS dataset, SP.SP_machine_name AS storage_server,
       AUSN.AUS_name AS archive_update_state, DA.AS_update_state_Last_Affected AS update_last_affected, DASN.DASN_StateName AS archive_state,
       DA.AS_state_Last_Affected AS last_affected, InstName.IN_name AS instrument, AP.AP_archive_path AS archive_path,
       AP.AP_Server_Name AS archive_server, DS.DS_created AS ds_created, DA.AS_last_update AS last_update
FROM dbo.T_Dataset_Archive AS DA INNER JOIN
     dbo.T_Dataset AS DS ON DA.AS_Dataset_ID = DS.Dataset_ID INNER JOIN
     dbo.T_DatasetArchiveStateName AS DASN ON DA.AS_state_ID = DASN.DASN_StateID INNER JOIN
     dbo.T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID INNER JOIN
     dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
     dbo.T_Archive_Update_State_Name AS AUSN ON DA.AS_update_state_ID = AUSN.AUS_stateID INNER JOIN
     dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.sp_path_id
WHERE (NOT (DA.AS_update_state_ID IN (4, 6)))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Check_Update_Report] TO [DDL_Viewer] AS [dbo]
GO
