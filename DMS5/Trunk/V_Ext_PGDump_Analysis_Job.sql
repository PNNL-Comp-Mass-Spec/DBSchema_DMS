/****** Object:  View [dbo].[V_Ext_PGDump_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Analysis_Job
AS
SELECT     AJ.AJ_jobID AS id, AJ.AJ_created AS created, AT.AJT_toolName AS analysis_tool_name, AJ.AJ_resultsFolderName AS results_folder_name, 
                      AJ.AJ_comment AS comment, AJ.AJ_datasetID AS dataset_id, AJ.AJ_datasetID AS ds_id
FROM         dbo.T_Analysis_Job AS AJ INNER JOIN
                      dbo.T_Analysis_Tool AS AT ON AJ.AJ_analysisToolID = AT.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job] TO [PNL\D3M580] AS [dbo]
GO
