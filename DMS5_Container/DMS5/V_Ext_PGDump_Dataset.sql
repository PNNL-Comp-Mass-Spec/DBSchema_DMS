/****** Object:  View [dbo].[V_Ext_PGDump_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Dataset
AS
SELECT     D.Dataset_ID AS id, D.Dataset_Num AS dataset_name, D.DS_created AS created, D.DS_comment AS comment, INN.IN_name AS instrument_name, 
                      DA.AS_storage_path_ID AS archive_path_id, D.DS_rating AS rating, D.Scan_Count, D.File_Size_Bytes, D.Exp_ID AS experiment_id, 
                      D.Dataset_ID AS ds_id
FROM         dbo.T_Dataset_Archive AS DA INNER JOIN
                      dbo.T_Dataset AS D ON DA.AS_Dataset_ID = D.Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name AS INN ON D.DS_instrument_name_ID = INN.Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset] TO [PNL\D3M580] AS [dbo]
GO
