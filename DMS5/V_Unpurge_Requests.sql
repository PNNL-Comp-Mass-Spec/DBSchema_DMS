/****** Object:  View [dbo].[V_Unpurge_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Unpurge_Requests
AS
SELECT     TOP 100 PERCENT dbo.T_Analysis_Job.AJ_jobID AS JobID, dbo.T_Dataset.Dataset_ID AS DatasetID, 
                      REPLACE(dbo.t_storage_path.SP_vol_name_client, '\', '') AS StorageServerName, dbo.t_storage_path.SP_vol_name_server AS ServerVol
FROM         dbo.t_storage_path INNER JOIN
                      dbo.T_Dataset ON dbo.t_storage_path.SP_path_ID = dbo.T_Dataset.DS_storage_path_ID INNER JOIN
                      dbo.T_Analysis_Job ON dbo.T_Dataset.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID
WHERE     (dbo.T_Analysis_Job.AJ_StateID = 10)
ORDER BY dbo.T_Analysis_Job.AJ_priority



GO
GRANT VIEW DEFINITION ON [dbo].[V_Unpurge_Requests] TO [DDL_Viewer] AS [dbo]
GO
