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
**          02/27/2019 mem - Use T_Storage_Path_Hosts instead of SP_URL
**          09/06/2022 mem - When @processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**
*****************************************************/
(
    @processingMode tinyint = 0,        -- 0 to only process new datasets and datasets with UpdateRequired = 1
                                        -- 1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 3 to re-process all of the entries in T_Cached_Dataset_Folder_Paths (this is the slowest update and will take 10 to 20 seconds)
    @message varchar(512) = '' output,
    @showDebug tinyint = 0
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @minimumDatasetID int = 0

    Declare @datasetIdStart int
    Declare @datasetIdEnd int
    Declare @datasetIdMax int
    Declare @datasetBatchSize int
    Declare @continue tinyint

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @processingMode = IsNull(@processingMode, 0)
    Set @message = ''
    Set @showDebug = IsNull(@showDebug, 0)

    If @processingMode IN (0, 1)
    Begin
        SELECT @minimumDatasetID = MIN(Dataset_ID)
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
    WHERE DS.Dataset_ID >= @minimumDatasetID AND
          DFP.Dataset_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.CheckPlural(@myRowCount, 'dataset', 'datasets')

    SELECT @datasetIdMax = Max(Dataset_ID)
    FROM T_Cached_Dataset_Links
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @datasetIdMax = 2147483647
    End

    If @processingMode >= 3 And @datasetIdMax < 2147483647
    Begin
        Set @datasetBatchSize = 50000
    End
    Else
    Begin
        Set @datasetBatchSize = 0
    End

    If @processingMode IN (1,2)
    Begin
        If @showDebug > 0
        Begin
            Print 'Setting UpdateRequired to 1 in T_Cached_Dataset_Folder_Paths for datasets with Dataset_ID >= ' + Cast(@minimumDatasetID as Varchar(12)) + ' and differing row versions'
        End

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
        WHERE DS.Dataset_ID >= @minimumDatasetID AND
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
        WHERE DS.Dataset_ID >= @minimumDatasetID AND
              DS.DS_RowVersion <> DFP.DS_RowVersion
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
            Set @message = dbo.AppendToText(@message,
                                            Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' dataset differs', ' datasets differ') + ' on DS_RowVersion',
                                            0, '; ', 512)

    End

    If @processingMode < 3
    Begin
        If @showDebug > 0
        Begin
            Print 'Updating cached paths for all rows in T_Cached_Dataset_Folder_Paths where UpdateRequired is 1'
        End

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
            -- Old: Dataset_URL =             SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/',
            Dataset_URL = CASE WHEN SPath.SP_function Like '%inbox%'
                          THEN ''
                          ELSE SPH.URL_Prefix +
                               SPH.Host_Name + SPH.DNS_Suffix + '/' +
                               Replace([SP_path], '\', '/')
                          END +
                          ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/',
            UpdateRequired = 0,
            Last_Affected = GetDate()
        FROM T_Dataset DS
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DFP.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN T_Storage_Path SPath
               ON SPath.SP_path_ID = DS.DS_storage_path_ID
             LEFT OUTER JOIN T_Storage_Path_Hosts SPH
               ON SPath.SP_machine_name = SPH.SP_machine_name
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
        -- @processingMode is 3

        If @showDebug > 0
        Begin
            If @datasetBatchSize > 0
                Print 'Updating cached paths for all rows in T_Cached_Dataset_Folder_Paths, processing ' + Cast(@datasetBatchSize As Varchar(12)) + ' datasets at a time'
            Else
                Print 'Updating cached paths all rows in T_Cached_Dataset_Folder_Paths; note that batch size is 0, which should never be the case'
        End

        Set @continue = 1
        Set @datasetIdStart = 0

        If @datasetBatchSize > 0
            Set @datasetIdEnd = @datasetIdStart + @datasetBatchSize - 1
        Else
            Set @datasetIdEnd = @datasetIdMax

        While @continue > 0
        Begin
            If @showDebug > 0
            Begin
                Print 'Updating Dataset IDs ' + Cast(@datasetIdStart As Varchar(12)) + ' to ' + Cast(@datasetIdEnd As Varchar(12))
            End

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
                       -- Old:             SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS Dataset_URL
                       CASE WHEN SPath.SP_function Like '%inbox%'
                            THEN ''
                            ELSE SPH.URL_Prefix +
                                 SPH.Host_Name + SPH.DNS_Suffix + '/' +
                                 Replace([SP_path], '\', '/')
                            END +
                            ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS Dataset_URL
                FROM T_Dataset DS
                     INNER JOIN T_Cached_Dataset_Folder_Paths DFP
                       ON DFP.Dataset_ID = DS.Dataset_ID
                     LEFT OUTER JOIN T_Storage_Path SPath
                       ON SPath.SP_path_ID = DS.DS_storage_path_ID
                     LEFT OUTER JOIN T_Storage_Path_Hosts SPH
                       ON SPath.SP_machine_name = SPH.SP_machine_name
                     LEFT OUTER JOIN T_Dataset_Archive DA
                                     INNER JOIN T_Archive_Path AP
                                       ON DA.AS_storage_path_ID = AP.AP_path_ID
                       ON DS.Dataset_ID = DA.AS_Dataset_ID
                WHERE DS.Dataset_ID BETWEEN @datasetIdStart AND @datasetIdEnd
            ) AS Source (Dataset_ID, DS_RowVersion, SPath_RowVersion, Dataset_Folder_Path, Archive_Folder_Path, MyEMSL_Path_Flag, Dataset_URL)
            ON (target.Dataset_ID = source.Dataset_ID)
            WHEN Matched AND
                            (   IsNull(target.DS_RowVersion,        0) <> IsNull(source.DS_RowVersion,        0) OR
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

            If @datasetBatchSize <= 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Set @datasetIdStart = @datasetIdStart + @datasetBatchSize
                Set @datasetIdEnd = @datasetIdEnd + @datasetBatchSize

                If @datasetIdStart > @datasetIdMax
                Begin
                    Set @continue = 0
                End
            End
        End
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
