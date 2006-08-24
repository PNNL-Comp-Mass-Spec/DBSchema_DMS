/****** Object:  View [dbo].[V_Analysis_Job_Dataset_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Analysis_Job_Dataset_Picker
AS
SELECT AJ_jobID AS JobID, CAST(AJ_jobID AS VARCHAR(15)) + '(' + Dataset_Num + ')' AS JobDataset 
FROM t_analysis_job a join t_dataset d ON a.AJ_DatasetID = d.Dataset_ID and d.Dataset_Num like 'QC_%'

GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Dataset_Picker] TO [DMS_SP_User]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Dataset_Picker] ([JobID]) TO [DMS_SP_User]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Dataset_Picker] ([JobDataset]) TO [DMS_SP_User]
GO
