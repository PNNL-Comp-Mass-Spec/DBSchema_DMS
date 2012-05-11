/****** Object:  View [dbo].[V_Data_Helper_Dataset_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Data_Helper_Dataset_Lookup
AS
SELECT     DA.AS_Dataset_ID AS id, DS.Dataset_Num AS name, DASN.DASN_StateName AS state, APath.AP_archive_path AS archive_path, 
                      DA.AS_instrument_data_purged AS is_purged
FROM         dbo.T_Dataset_Archive AS DA INNER JOIN
                      dbo.T_Dataset AS DS ON DA.AS_Dataset_ID = DS.Dataset_ID INNER JOIN
                      dbo.T_DatasetArchiveStateName AS DASN ON DA.AS_state_ID = DASN.DASN_StateID INNER JOIN
                      dbo.T_Archive_Path AS APath ON DA.AS_storage_path_ID = APath.AP_path_ID

GO
