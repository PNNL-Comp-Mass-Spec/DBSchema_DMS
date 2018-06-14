/****** Object:  StoredProcedure [dbo].[UpdateCachedDatasetFolderPaths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCachedDatasetFolderPaths]
/****************************************************
**
**  Desc:   Updates T_Cached_Dataset_Folder_Paths
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/14/2013 mem - Initial version
**          11/15/2013 mem - Added parameter
**          11/19/2013 mem - Tweaked logging
**          06/12/2018 mem - Send @maxLength to AppendToText
**    
*****************************************************/
(
    @ProcessingMode tinyint = 0,        -- 0 to only process new datasets and datasets with UpdateRequired = 1
                                        -- 1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 3 to re-process all of the entries in T_Cached_Dataset_Folder_Paths (this is the slowest update and will take 10 to 20 seconds)
    @message varchar(512) = '' output    
)
As
    Set nocount on
    
    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0
    
    Declare @MinimumDatasetID int = 0
    
    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @ProcessingMode = IsNull(@ProcessingMode, 0)
    Set @message = ''
    
    If @ProcessingMode IN (0, 1)
    Begin
        SELECT @MinimumDatasetID = MIN(Dataset_ID)
        FROM ( SELECT TOP 10000 Dataset_ID
               FROM T_Dataset
               ORDER BY Dataset_ID DESC ) LookupQ
    End

    
    ------------------------------------------------
    -- Add new datasets to T_Cached_Dataset_Folder_Paths
    ------------------------------------------------
    --
    INSERT INTO T_Cached_Dataset_Folder_Paths (Dataset_ID,
                                               DS_RowVersion,                                               
                                               UpdateRequired )
    SELECT DS.Dataset_ID,
           DS.DS_RowVersion,
           1 AS UpdateRequired
    FROM T_Dataset DS
         LEFT OUTER JOIN T_Cached_Dataset_Folder_Paths DFP
           ON DFP.Dataset_ID = DS.Dataset_ID
         LEFT OUTER JOIN T_Storage_Path SPath
           ON SPath.SP_path_ID = DS.DS_storage_path_ID
         LEFT OUTER JOIN T_Dataset_Archive DA
                         INNER JOIN T_Archive_Path AP
                           ON DA.AS_storage_path_ID = AP.AP_path_ID
           ON DS.Dataset_ID = DA.AS_Dataset_ID
    WHERE DS.Dataset_ID >= @MinimumDatasetID AND 
          DFP.Dataset_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.CheckPlural(@myRowCount, 'dataset', 'datasets')


    If @ProcessingMode IN (1,2)
    Begin

        ------------------------------------------------
        -- Find datasets that need to be updated
        --
        -- Notes regarding T_Dataset_Archive
        --   Trigger trig_i_Dataset_Archive will set UpdateRequired to 1 when a dataset is added to T_Dataset_Archive
        --   Trigger trig_u_Dataset_Archive will set UpdateRequired to 1 when AS_storage_path_ID is updated
        ------------------------------------------------

        ------------------------------------------------
        -- Find existing entries with a mismatch in SPath_RowVersion
        ------------------------------------------------
        --
        UPDATE T_Cached_Dataset_Folder_Paths
        SET UpdateRequired = 1
        FROM T_Dataset DS
             INNER JOIN T_Storage_Path SPath
               ON SPath.SP_path_ID = DS.DS_storage_path_ID
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DS.Dataset_ID = DFP.Dataset_ID
        WHERE DS.Dataset_ID >= @MinimumDatasetID AND
              SPath.SPath_RowVersion <> DFP.SPath_RowVersion
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
            Set @message = dbo.AppendToText(@message, 
                                            Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' dataset differs', ' datasets differ') + ' on SPath_RowVersion', 
                                            0, '; ', 512)
        
        ------------------------------------------------
        -- Find existing entries with a mismatch in DS_RowVersion
        ------------------------------------------------
        --
        UPDATE T_Cached_Dataset_Folder_Paths
        SET UpdateRequired = 1
        FROM T_Dataset DS
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DFP.Dataset_ID = DS.Dataset_ID
        WHERE DS.Dataset_ID >= @MinimumDatasetID AND
              DS.DS_RowVersion <> DFP.DS_RowVersion
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
            Set @message = dbo.AppendToText(@message, 
                                            Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' dataset differs', ' datasets differ') + ' on DS_RowVersion', 
                                            0, '; ', 512)

    End
    
    IF @ProcessingMode < 3
    Begin
        ------------------------------------------------
        -- Update entries with UpdateRequired > 0
        -- Note that this query runs 2x faster than the merge statement below
        -- If you update this query, be sure to update the merge statement
        ------------------------------------------------
        --
        UPDATE T_Cached_Dataset_Folder_Paths
        SET DS_RowVersion = DS.DS_RowVersion,
            SPath_RowVersion = SPath.SPath_RowVersion,
            Dataset_Folder_Path = ISNULL(dbo.udfCombinePaths(SPath.SP_vol_name_client, 
                                         dbo.udfCombinePaths(SPath.SP_path, ISNULL(DS.DS_folder_name, DS.Dataset_Num))), ''),
            Archive_Folder_Path = CASE
                                      WHEN AP.AP_network_share_path IS NULL THEN ''
                                      ELSE dbo.udfCombinePaths(AP.AP_network_share_path, 
                                                               ISNULL(DS.DS_folder_name, DS.Dataset_Num))
                                  END,
            MyEMSL_Path_Flag = '\\MyEMSL\' + dbo.udfCombinePaths(SPath.SP_path, ISNULL(DS.DS_folder_name, DS.Dataset_Num)),
            Dataset_URL = SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/',
            UpdateRequired = 0,
            Last_Affected = GetDate()
        FROM T_Dataset DS
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DFP.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN T_Storage_Path SPath
               ON SPath.SP_path_ID = DS.DS_storage_path_ID
             LEFT OUTER JOIN T_Dataset_Archive DA
                             INNER JOIN T_Archive_Path AP
                               ON DA.AS_storage_path_ID = AP.AP_path_ID
               ON DS.Dataset_ID = DA.AS_Dataset_ID
        WHERE DFP.UpdateRequired = 1
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End
    Else
    Begin
        ------------------------------------------------
        -- Update all of the entries (if the stored value disagrees)
        --        
        -- Note that this merge statement runs 2x slower than the query above
        -- If you update this merge statement, be sure to update the query
        ------------------------------------------------
        --
        MERGE T_Cached_Dataset_Folder_Paths as target
        USING (
            SELECT DS.Dataset_ID,
                   DS.DS_RowVersion AS DS_RowVersion,
                   SPath.SPath_RowVersion AS SPath_RowVersion,
                   ISNULL(dbo.udfCombinePaths(SPath.SP_vol_name_client, 
                          dbo.udfCombinePaths(SPath.SP_path, ISNULL(DS.DS_folder_name, DS.Dataset_Num))), '') AS Dataset_Folder_Path,
                   CASE
                       WHEN AP.AP_network_share_path IS NULL THEN ''
                       ELSE dbo.udfCombinePaths(AP.AP_network_share_path, 
                                                ISNULL(DS.DS_folder_name, DS.Dataset_Num))
                   END AS Archive_Folder_Path,
                   '\\MyEMSL\' + dbo.udfCombinePaths(SPath.SP_path, ISNULL(DS.DS_folder_name, DS.Dataset_Num)) AS MyEMSL_Path_Flag,
                   SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS Dataset_URL
            FROM T_Dataset DS
                 INNER JOIN T_Cached_Dataset_Folder_Paths DFP
                   ON DFP.Dataset_ID = DS.Dataset_ID
                 LEFT OUTER JOIN T_Storage_Path SPath
                   ON SPath.SP_path_ID = DS.DS_storage_path_ID
                 LEFT OUTER JOIN T_Dataset_Archive DA
                                 INNER JOIN T_Archive_Path AP
                                   ON DA.AS_storage_path_ID = AP.AP_path_ID
                   ON DS.Dataset_ID = DA.AS_Dataset_ID
        ) AS Source (Dataset_ID, DS_RowVersion, SPath_RowVersion, Dataset_Folder_Path, Archive_Folder_Path, MyEMSL_Path_Flag, Dataset_URL)
        ON (target.Dataset_ID = source.Dataset_ID)
        WHEN Matched AND 
                        (    IsNull(target.DS_RowVersion,        0) <> IsNull(source.DS_RowVersion,        0) OR
                            IsNull(target.SPath_RowVersion,     0) <> IsNull(source.SPath_RowVersion,     0) OR
                            IsNull(target.Dataset_Folder_Path, '') <> IsNull(source.Dataset_Folder_Path, '') OR
                            IsNull(target.Archive_Folder_Path, '') <> IsNull(source.Archive_Folder_Path, '') OR
                            IsNull(target.MyEMSL_Path_Flag,    '') <> IsNull(source.MyEMSL_Path_Flag,    '') OR
                            IsNull(target.Dataset_URL,         '') <> IsNull(source.Dataset_URL,         '')                        
                        )
        THEN UPDATE 
             Set DS_RowVersion = source.DS_RowVersion,
                 SPath_RowVersion = source.SPath_RowVersion,
                 Dataset_Folder_Path = source.Dataset_Folder_Path,
                 Archive_Folder_Path = source.Archive_Folder_Path,
                 MyEMSL_Path_Flag = source.MyEMSL_Path_Flag,
                 Dataset_URL = source.Dataset_URL,
                 UpdateRequired = 0,
                 Last_Affected = GetDate()
        ;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    
    If @myRowCount > 0
    Begin
        Set @message = dbo.AppendToText(@message,
                                        'Updated ' + Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' row', ' rows') + ' in T_Cached_Dataset_Folder_Paths', 
                                        0, '; ', 512)
                                        
        -- Exec PostLogEntry 'Debug', @message, 'UpdateCachedDatasetFolderPaths'
    End
    
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedDatasetFolderPaths] TO [DDL_Viewer] AS [dbo]
GO
