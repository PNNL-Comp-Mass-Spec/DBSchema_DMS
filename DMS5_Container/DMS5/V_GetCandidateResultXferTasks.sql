/****** Object:  View [dbo].[V_GetCandidateResultXferTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetCandidateResultXferTasks
AS
SELECT     AJ.AJ_jobID AS JobID, AJ.AJ_StateID AS JobStateID, StoragePath.SP_machine_name AS ServerName, AJ.AJ_Last_Affected AS Last_Affected
FROM         dbo.T_Analysis_Job AS AJ INNER JOIN
                      dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
                      dbo.t_storage_path AS StoragePath ON DS.DS_storage_path_ID = StoragePath.SP_path_ID
WHERE     (AJ.AJ_StateID = 3)

GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCandidateResultXferTasks] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCandidateResultXferTasks] TO [PNL\D3M580] AS [dbo]
GO
