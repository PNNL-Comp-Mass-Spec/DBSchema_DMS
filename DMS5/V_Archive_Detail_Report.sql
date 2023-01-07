/****** Object:  View [dbo].[V_Archive_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_Detail_Report]
AS
SELECT DS.Dataset_Num AS dataset,
       DS.Dataset_ID AS id,
       TIN.IN_name AS instrument,
       DS.DS_created AS created,
       DASN.DASN_StateName AS state,
       AUS.AUS_name AS [update],
       DA.AS_datetime AS entered,
       DA.AS_last_update AS last_update,
       DA.AS_last_verify AS last_verify,
       TAP.AP_archive_path AS archive_path,
       TAP.AP_Server_Name AS archive_server,
       DA.AS_instrument_data_purged AS instrument_data_purged,
       CASE
           WHEN DA.MyEMSLState > 0 THEN
             REPLACE(TAP.ap_network_share_path, '\\adms.emsl.pnl.gov\dmsarch\', '\\MyEMSL\svc-dms\')
           ELSE TAP.AP_network_share_path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num)
       END AS network_share_path,
        CASE
           WHEN DA.MyEMSLState > 0 THEN 'https://my.emsl.pnl.gov/myemsl/search/simple/'
           ELSE TAP.AP_archive_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num)
           END AS archive_url
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetArchiveStateName DASN
       ON DA.AS_state_ID = DASN.DASN_StateID
     INNER JOIN dbo.T_Archive_Path TAP
       ON DA.AS_storage_path_ID = TAP.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
     INNER JOIN dbo.T_Archive_Update_State_Name AUS
       ON DA.AS_update_state_ID = AUS.AUS_stateID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
