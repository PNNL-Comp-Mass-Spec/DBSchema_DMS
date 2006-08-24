/****** Object:  View [dbo].[V_Restore_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Restore_Requests
AS
SELECT TOP 100 PERCENT dbo.T_Dataset.Dataset_ID AS DatasetID, REPLACE(dbo.t_storage_path.SP_vol_name_client, '\', '') AS StorageServerName, 
               dbo.t_storage_path.SP_vol_name_server AS ServerVol
FROM  dbo.t_storage_path INNER JOIN
               dbo.T_Dataset ON dbo.t_storage_path.SP_path_ID = dbo.T_Dataset.DS_storage_path_ID
WHERE (dbo.T_Dataset.DS_state_ID = 10)


GO
