-- Use the following to validate that the cached folder paths are correct:

DECLARE @DatasetIDMinimum int = 250000
Declare @DatasetCount int
Declare @DatasetCountMatch int

SELECT @DatasetCount = COUNT(*)
FROM V_Dataset_Folder_Paths_Slow_DoNotUse DFPOld INNER JOIN
   V_Dataset_Folder_Paths DFP ON DFPOld.Dataset_ID = DFP.Dataset_ID  
WHERE (DFPOld.Dataset_ID >= @DatasetIDMinimum)

SELECT @DatasetCountMatch = COUNT(*)
FROM V_Dataset_Folder_Paths_Slow_DoNotUse DFPOld INNER JOIN
   V_Dataset_Folder_Paths DFP ON DFPOld.Dataset_ID = DFP.Dataset_ID AND 
   IsNull(DFPOld.Dataset_Folder_Path, '') = IsNull(DFP.Dataset_Folder_Path, '') AND 
   IsNull(DFPOld.Archive_Folder_Path, '') = IsNull(DFP.Archive_Folder_Path, '') AND 
   IsNull(DFPOld.MyEMSL_Path_Flag, '') = IsNull(DFP.MyEMSL_Path_Flag, '') AND 
   IsNull(DFPOld.Dataset_URL, '') = IsNull(DFP.Dataset_URL, '') AND 
   IsNull(DFPOld.Instrument_Data_Purged, '') = IsNull(DFP.Instrument_Data_Purged, '')
WHERE (DFPOld.Dataset_ID >= @DatasetIDMinimum)


SELECT @DatasetCount,
       @DatasetCountMatch,
       CASE
           WHEN @DatasetCountMatch = @DatasetCount THEN 'Counts Match'
           ELSE 'ERROR: Counts do not agree'
       END AS Message



/*
ALTER VIEW [dbo].[V_Dataset_Folder_Paths_Slow_DoNotUse]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       ISNULL(dbo.udfCombinePaths(SPath.SP_vol_name_client, 
              dbo.udfCombinePaths(SPath.SP_path, 
                                  ISNULL(DS.DS_folder_name, DS.Dataset_Num))), '') AS Dataset_Folder_Path,
       CASE
           WHEN DAP.Archive_Path IS NULL THEN ''
           ELSE dbo.udfCombinePaths(DAP.Archive_Path, ISNULL(DS.DS_folder_name, DS.Dataset_Num))
       END AS Archive_Folder_Path,
       '\\MyEMSL\' + dbo.udfCombinePaths(SPath.SP_path, ISNULL(DS.DS_folder_name, DS.Dataset_Num)) AS MyEMSL_Path_Flag,
       SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS Dataset_URL,
       DAP.Instrument_Data_Purged
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path DAP
       ON DS.Dataset_ID = DAP.Dataset_ID
*/
