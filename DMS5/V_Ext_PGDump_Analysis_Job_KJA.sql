/****** Object:  View [dbo].[V_Ext_PGDump_Analysis_Job_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Analysis_Job_KJA
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS id, dbo.T_Analysis_Job.AJ_created AS created, dbo.T_Analysis_Tool.AJT_toolName AS analysis_tool_name, 
                      dbo.T_Analysis_Job.AJ_resultsFolderName AS results_folder_name, dbo.T_Analysis_Job.AJ_comment AS comment, 
                      dbo.T_Analysis_Job.AJ_datasetID AS dataset_id
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Analysis_Job_KJA] TO [PNL\D3M580] AS [dbo]
GO
