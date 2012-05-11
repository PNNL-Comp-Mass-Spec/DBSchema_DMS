/****** Object:  View [dbo].[V_Ext_PGDump_Archive_Path_Aj] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Archive_Path_Aj
AS
SELECT	AP.AP_path_ID AS id, 
		INN.IN_name AS instrument_name, 
		AP.AP_archive_path AS archive_path,
		AP.Note AS note,
		AJ.AJ_JobId AS aj_id
FROM	T_Archive_Path AP
		JOIN	T_Instrument_Name INN ON AP.AP_instrument_name_ID = INN.Instrument_ID
		JOIN	T_Dataset_Archive DA ON DA.AS_storage_path_ID = AP.AP_path_ID
		JOIN	T_Analysis_Job AJ ON AJ.AJ_datasetID = DA.AS_Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path_Aj] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path_Aj] TO [PNL\D3M580] AS [dbo]
GO
