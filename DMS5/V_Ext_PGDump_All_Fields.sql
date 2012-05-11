/****** Object:  View [dbo].[V_Ext_PGDump_All_Fields] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW[dbo].[V_Ext_PGDump_All_Fields]
AS
SELECT	Campaign_ID AS cmp_id, 
		Campaign_Num AS campaign_name, 
		CM_created AS cmp_created, 
		CM_comment AS cmp_comment,
--
		E.Exp_ID AS ex_id, 
		E.Experiment_Num AS experiment_name, 
		E.EX_created AS ex_created, 
		O.OG_name AS organism_name, 
		E.EX_reason AS reason, 
		E.EX_cell_culture_list AS biomaterial_list, 
		E.EX_campaign_ID AS campaign_id,
--
		D.Dataset_ID AS ds_id, 
		D.Dataset_Num AS dataset_name, 
		D.DS_created AS ds_created, 
		D.DS_comment AS ds_comment, 
		INN.IN_name AS instrument_name, 
		DA.AS_storage_path_ID AS archive_path_id, 
		D.DS_rating AS rating, 
		D.Scan_Count AS scan_count, 
		D.File_Size_Bytes AS file_size_bytes, 
		D.Exp_ID AS experiment_id,
--
		AJ.AJ_jobID AS aj_id, 
		AJ.AJ_created AS aj_created, 
		AT.AJT_toolName AS analysis_tool_name, 
		AJ.AJ_resultsFolderName AS results_folder_name, 
		AJ.AJ_comment AS aj_comment, 
		AJ.AJ_datasetID AS dataset_id,
--
		O.Organism_ID AS org_id, 
		O.OG_name AS name, 
		CASE WHEN O.OG_genus IS NOT NULL 
			THEN COALESCE (O.OG_Genus, '') + ' ' + COALESCE (O.OG_Species, '') + ' ' + COALESCE (O.OG_Strain, '') 
			ELSE O.OG_name
			END AS full_name,
--
		AP.AP_path_ID AS ap_id, 
		AP.AP_archive_path AS archive_path,
		AP.Note AS note
FROM	T_Dataset D 
		LEFT JOIN	T_Experiments E ON D.Exp_ID = E.Exp_ID
		LEFT JOIN	T_Organisms O ON E.EX_organism_ID = O.Organism_ID
		LEFT JOIN	T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID
		LEFT JOIN	T_Dataset_Archive DA ON DA.AS_Dataset_ID = D.Dataset_ID 
		LEFT JOIN	T_Instrument_Name INN ON D.DS_instrument_name_ID = INN.Instrument_ID
		LEFT JOIN	T_Analysis_Job AJ ON AJ.AJ_datasetID = D.Dataset_ID
		LEFT JOIN	T_Analysis_Tool AT ON AJ.AJ_analysisToolID = AT.AJT_toolID
		LEFT JOIN	T_Archive_Path AP ON DA.AS_storage_path_ID = AP.AP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_All_Fields] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_All_Fields] TO [PNL\D3M580] AS [dbo]
GO
