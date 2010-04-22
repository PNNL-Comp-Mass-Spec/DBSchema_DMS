/****** Object:  View [dbo].[V_Ext_PGDump_Dataset_Aj] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Dataset_Aj
AS
SELECT	D.Dataset_ID AS id, 
		D.Dataset_Num AS dataset_name, 
		D.DS_created AS created, 
		D.DS_comment AS comment, 
		INN.IN_name AS instrument_name, 
		DA.AS_storage_path_ID AS archive_path_id, 
		D.DS_rating AS rating, 
		D.Scan_Count AS scan_count, 
		D.File_Size_Bytes AS file_size_bytes, 
		D.Exp_ID AS experiment_id,
		AJ.AJ_jobID AS aj_id
FROM	T_Dataset_Archive DA
		JOIN	T_Dataset D ON DA.AS_Dataset_ID = D.Dataset_ID 
		JOIN	T_Instrument_Name INN ON D.DS_instrument_name_ID = INN.Instrument_ID
		JOIN	T_Analysis_Job AJ ON AJ.AJ_datasetID = D.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset_Aj] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Dataset_Aj] TO [PNL\D3M580] AS [dbo]
GO
