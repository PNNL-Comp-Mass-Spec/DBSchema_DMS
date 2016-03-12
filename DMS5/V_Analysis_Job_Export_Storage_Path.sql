/****** Object:  View [dbo].[V_Analysis_Job_Export_Storage_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Export_Storage_Path]
AS
SELECT AJ.AJ_jobID AS Job,
       DS.Dataset_Num AS Dataset,
       DSArch.Archive_Path + '\' AS StoragePathClient,
       dbo.udfCombinePaths(SP.SP_vol_name_client, SP.SP_path) AS StoragePathServer,
       DS.DS_folder_name AS DatasetFolder,
       AJ.AJ_resultsFolderName AS ResultsFolder
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.V_Dataset_Archive_Path DSArch
       ON DS.Dataset_ID = DSArch.Dataset_ID
     INNER JOIN dbo.t_storage_path SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
WHERE (AJ.AJ_StateID IN (4,14))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_Storage_Path] TO [PNL\D3M578] AS [dbo]
GO
