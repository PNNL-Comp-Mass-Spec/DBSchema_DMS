/****** Object:  View [dbo].[V_Ext_PGDump_Analysis_Job_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Analysis_Job_Ex
AS
SELECT	AJ.AJ_jobID AS id, 
		AJ.AJ_created AS created, 
		AT.AJT_toolName AS analysis_tool_name, 
		AJ.AJ_resultsFolderName AS results_folder_name, 
		AJ.AJ_comment AS comment,
		AJ.AJ_datasetID as dataset_id,
		E.Exp_ID AS ex_id
FROM    T_Analysis_Job AJ
		JOIN	T_Analysis_Tool AT ON AJ.AJ_analysisToolID = AT.AJT_toolID
		JOIN	T_Dataset D ON D.Dataset_ID = AJ.AJ_datasetID
		JOIN	T_Experiments E ON E.Exp_ID = D.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job_Ex] TO [PNL\D3M580] AS [dbo]
GO
