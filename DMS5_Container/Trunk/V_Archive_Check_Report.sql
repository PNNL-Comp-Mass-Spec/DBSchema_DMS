/****** Object:  View [dbo].[V_Archive_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Check_Report
AS
SELECT     DS.Dataset_ID AS [Dataset ID], DS.Dataset_Num AS Dataset, DASN.DASN_StateName AS [Archive State], DA.AS_state_Last_Affected AS [Last Affected], 
                      InstName.IN_name AS Instrument, SP.SP_machine_name AS [Storage Server], AP.AP_archive_path AS [Archive Path], 
                      DA.AS_archive_processor AS [Archive Processor], DA.AS_update_processor AS [Update Processor], 
                      DA.AS_verification_processor AS [Verification Processor]
FROM         dbo.T_Dataset_Archive AS DA INNER JOIN
                      dbo.T_DatasetArchiveStateName AS DASN ON DA.AS_state_ID = DASN.DASN_StateID INNER JOIN
                      dbo.T_Dataset AS DS ON DA.AS_Dataset_ID = DS.Dataset_ID INNER JOIN
                      dbo.T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID INNER JOIN
                      dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE     (DA.AS_state_ID NOT IN (3, 4, 9, 10))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Check_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Check_Report] TO [PNL\D3M580] AS [dbo]
GO
