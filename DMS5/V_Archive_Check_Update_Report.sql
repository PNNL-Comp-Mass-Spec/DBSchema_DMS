/****** Object:  View [dbo].[V_Archive_Check_Update_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Check_Update_Report
AS
SELECT     DA.AS_Dataset_ID AS [Dataset ID], DS.Dataset_Num AS Dataset, SP.SP_machine_name AS [Storage Server], 
                      AUSN.AUS_name AS [Archive Update State], DA.AS_update_state_Last_Affected AS [Update Last Affected], DASN.DASN_StateName AS [Archive State], 
                      DA.AS_state_Last_Affected AS [Last Affected], InstName.IN_name AS Instrument, AP.AP_archive_path AS [Archive Path], 
                      AP.AP_Server_Name AS [Archive Server], DS.DS_created AS [DS Created], DA.AS_last_update AS [Last Update]
FROM         dbo.T_Dataset_Archive AS DA INNER JOIN
                      dbo.T_Dataset AS DS ON DA.AS_Dataset_ID = DS.Dataset_ID INNER JOIN
                      dbo.T_DatasetArchiveStateName AS DASN ON DA.AS_state_ID = DASN.DASN_StateID INNER JOIN
                      dbo.T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID INNER JOIN
                      dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
                      dbo.T_Archive_Update_State_Name AS AUSN ON DA.AS_update_state_ID = AUSN.AUS_stateID INNER JOIN
                      dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID
WHERE     (NOT (DA.AS_update_state_ID IN (4, 6)))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Check_Update_Report] TO [PNL\D3M578] AS [dbo]
GO
