/****** Object:  View [dbo].[V_Ext_PGDump_Dataset_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Dataset_KJA
AS
SELECT     dbo.T_Dataset.Dataset_ID AS id, dbo.T_Dataset.Dataset_Num AS dataset_name, dbo.T_Dataset.DS_created AS created, 
                      dbo.T_Dataset.DS_comment AS comment, dbo.T_Instrument_Name.IN_name AS instrument_name, 
                      dbo.T_Dataset_Archive.AS_storage_path_ID AS archive_path_id, dbo.T_Dataset.DS_rating AS rating, dbo.T_Dataset.Scan_Count AS scan_count, 
                      dbo.T_Dataset.File_Size_Bytes AS file_size_bytes, dbo.T_Dataset.Exp_ID AS experiment_id
FROM         dbo.T_Dataset_Archive INNER JOIN
                      dbo.T_Dataset ON dbo.T_Dataset_Archive.AS_Dataset_ID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset_KJA] TO [PNL\D3M580] AS [dbo]
GO
