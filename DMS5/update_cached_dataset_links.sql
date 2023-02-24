/****** Object:  StoredProcedure [dbo].[update_cached_dataset_links] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_dataset_links]
/****************************************************
**
**  Desc:   Updates T_Cached_Dataset_Links, which is used by the
**          Dataset Detail Report view (V_Dataset_Detail_Report_Ex)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**          06/12/2018 mem - Send @maxLength to append_to_text
**          07/31/2020 mem - Update MASIC_Directory_Name
**          09/06/2022 mem - When @processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processingMode tinyint = 0,        -- 0 to only process new datasets and datasets with UpdateRequired = 1
                                        -- 1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for DS_RowVersion or SPath_RowVersion differing)
                                        -- 3 to re-process all of the entries in T_Cached_Dataset_Links (this is the slowest update and will take 10 to 20 seconds)
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
    Declare @datasetID int
    Declare @masicDirectoryName varchar(128)

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
    -- Add new datasets to T_Cached_Dataset_Links
    ------------------------------------------------
    --
    INSERT INTO T_Cached_Dataset_Links (Dataset_ID,
                                        DS_RowVersion,
                                        SPath_RowVersion,
                                        UpdateRequired )
    SELECT DS.Dataset_ID,
           DS.DS_RowVersion,
           DFP.SPath_RowVersion,
           1 AS UpdateRequired
    FROM T_Dataset DS
         INNER JOIN T_Cached_Dataset_Folder_Paths DFP
           ON DS.Dataset_ID = DFP.Dataset_ID
         LEFT OUTER JOIN T_Cached_Dataset_Links DL
           ON DL.Dataset_ID = DS.Dataset_ID
    WHERE DS.Dataset_ID >= @minimumDatasetID AND
          DL.Dataset_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.check_plural(@myRowCount, 'dataset', 'datasets')

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
            Print 'Setting UpdateRequired to 1 in T_Cached_Dataset_Links for datasets with Dataset_ID >= ' + Cast(@minimumDatasetID as Varchar(12)) + ' and differing row versions'
        End

        ------------------------------------------------
        -- Find datasets that need to be updated
        --
        -- Notes regarding T_Cached_Dataset_Folder_Paths
        --   Trigger trig_u_Dataset_Folder_Paths will set UpdateRequired to 1 when a row is changed in T_Dataset_Folder_Paths
        --
        -- Notes regarding T_Dataset_Archive
        --   Trigger trig_i_Dataset_Archive will set UpdateRequired to 1 when a dataset is added to T_Dataset_Archive
        --   Trigger trig_u_Dataset_Archive will set UpdateRequired to 1 when any of the following columns is updated:
        --     AS_state_ID, AS_storage_path_ID, AS_instrument_data_purged, MyEMSLState, QC_Data_Purged
        ------------------------------------------------

        ------------------------------------------------
        -- Find existing entries with a mismatch in DS_RowVersion or SPath_RowVersion
        ------------------------------------------------
        --
        UPDATE T_Cached_Dataset_Links
        SET UpdateRequired = 1
        FROM T_Cached_Dataset_Links DL
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DFP.Dataset_ID = DL.Dataset_ID
        WHERE DL.Dataset_ID >= @minimumDatasetID AND
              (DL.DS_RowVersion <> DFP.DS_RowVersion OR
               DL.SPath_RowVersion <> DFP.SPath_RowVersion)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
            Set @message = dbo.append_to_text(@message,
                                            Convert(varchar(12), @myRowCount) + dbo.check_plural(@myRowCount, ' dataset differs', ' datasets differ') + ' on DS_RowVersion or SPath_RowVersion',
                                            0, '; ', 512)

    End

    If @processingMode < 1
    Begin -- <a1>
        If @showDebug > 0
        Begin
            Print 'Updating MASIC Directory Name in T_Cached_Dataset_Links where UpdateRequired is 1 (updating one dataset at a time)'
        End

        ------------------------------------------------
        -- Iterate over datasets with UpdateRequired > 0  (since there should not be many)
        -- For each, make sure they have an up-to-date MASIC_Directory_Name
        --
        -- This query should be kept in sync with the bulk update query below
        ------------------------------------------------

        Set @continue = 1
        Set @datasetID = 0

        While @continue > 0
        Begin -- <b1>

            SELECT TOP 1 @datasetID = Dataset_ID
            FROM T_Cached_Dataset_Links
            WHERE UpdateRequired > 0 AND Dataset_ID > @datasetID
            ORDER BY Dataset_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin -- <c1>
                Set @masicDirectoryName = ''

                SELECT @masicDirectoryName = MasicDirectoryName
                FROM ( SELECT OrderQ.DatasetID,
                              OrderQ.Job,
                              OrderQ.MasicDirectoryName,
                              Row_Number() OVER ( PARTITION BY OrderQ.DatasetID
                                                  ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC ) AS JobRank
                       FROM ( SELECT J.AJ_DatasetID AS DatasetID,
                                     J.AJ_jobID AS Job,
                                     J.AJ_resultsFolderName AS MasicDirectoryName,
                                     CASE
                                         WHEN J.AJ_StateID = 4 THEN 1
                                         WHEN J.AJ_StateID = 14 THEN 2
                                         ELSE 3
                                     END AS JobStateRank
                              FROM T_Analysis_Job J
                                   INNER JOIN T_Analysis_Tool T
                                     ON J.AJ_analysisToolID = T.AJT_toolID
                              WHERE J.AJ_datasetID = @datasetID AND
                                    T.AJT_toolName LIKE 'MASIC%' AND
                                    NOT J.AJ_resultsFolderName IS NULL
                            ) OrderQ
                     ) RankQ
                WHERE JobRank = 1
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0 And LEN(@masicDirectoryName) > 0
                Begin
                    UPDATE T_Cached_Dataset_Links
                    SET MASIC_Directory_Name = @masicDirectoryName
                    WHERE Dataset_ID = @datasetID
                End

            End -- </c1>
        End -- </b1>

    End -- </a1>
    Else
    Begin -- <a2>
        -- @processingMode is 1, 2, or 3

        If @showDebug > 0
        Begin
            If @processingMode >= 3
            Begin
                If @datasetBatchSize > 0
                    Print 'Validating MASIC_Directory_Name for all rows in T_Cached_Dataset_Links, processing ' + Cast(@datasetBatchSize As Varchar(12)) + ' datasets at a time'
                Else
                    Print 'Validating MASIC_Directory_Name for all rows in T_Cached_Dataset_Links; note that batch size is 0, which should never be the case'
            End
            Else
            Begin
                Print 'Updating MASIC_Directory_Name in T_Cached_Dataset_Links where UpdateRequired is 1 (bulk update)'
            End
        End

        Set @continue = 1
        Set @datasetIdStart = 0

        If @datasetBatchSize > 0
            Set @datasetIdEnd = @datasetIdStart + @datasetBatchSize - 1
        Else
            Set @datasetIdEnd = @datasetIdMax

        While @continue > 0
        Begin -- <b2>
            ------------------------------------------------
            -- Make sure that entries with UpdateRequired > 0 have an up-to-date MASIC_Directory_Name
            -- This is a bulk update query, which can take some time to run, though if @processingMode is 3, datasets are processed in baches
            -- It should be kept in sync with the above query that includes Row_Number()
            ------------------------------------------------
            --
            UPDATE T_Cached_Dataset_Links
            SET MASIC_Directory_Name = JobDirectoryQ.MasicDirectoryName
            FROM T_Cached_Dataset_Links Target
                 INNER JOIN ( SELECT DatasetID,
                                     MasicDirectoryName
                              FROM ( SELECT OrderQ.DatasetID,
                                            OrderQ.Job,
                                            OrderQ.MasicDirectoryName,
                                            Row_Number() OVER ( PARTITION BY OrderQ.DatasetID
                                                                ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC ) AS JobRank
                                     FROM ( SELECT J.AJ_DatasetID AS DatasetID,
                                                   J.AJ_jobID AS Job,
                                                   J.AJ_resultsFolderName AS MasicDirectoryName,
                                                   CASE
                                                       WHEN J.AJ_StateID = 4 THEN 1
                                                       WHEN J.AJ_StateID = 14 THEN 2
                                                       ELSE 3
                                                   END AS JobStateRank
                                            FROM T_Analysis_Job J
                                                 INNER JOIN T_Analysis_Tool T
                                                   ON J.AJ_analysisToolID = T.AJT_toolID
                                            WHERE T.AJT_toolName LIKE 'MASIC%' AND
                                                  NOT J.AJ_resultsFolderName IS NULL AND
                                                  J.AJ_DatasetID BETWEEN @datasetIdStart AND @datasetIdEnd
                                          ) OrderQ
                                    ) RankQ
                              WHERE JobRank = 1
                           ) JobDirectoryQ
                   ON Target.Dataset_ID = JobDirectoryQ.DatasetID
            WHERE (Target.UpdateRequired > 0 OR
                   @processingMode >= 3) AND
                  ISNULL(Target.MASIC_Directory_Name, '') <> JobDirectoryQ.MasicDirectoryName
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

        End -- </b2>
    END -- </a2>

    If @processingMode < 3
    Begin
        If @showDebug > 0
        Begin
            Print 'Updating cached paths for all rows in T_Cached_Dataset_Links where UpdateRequired is 1 (bulk update)'
        End

        ------------------------------------------------
        -- Update entries with UpdateRequired > 0
        -- Note that this query runs 2x faster than the merge statement below
        -- If you update this query, be sure to update the merge statement
        ------------------------------------------------
        --
        UPDATE T_Cached_Dataset_Links
        SET DS_RowVersion = DFP.DS_RowVersion,
            SPath_RowVersion = DFP.SPath_RowVersion,
            Dataset_Folder_Path = CASE
                WHEN DA.AS_state_ID = 4 THEN 'Purged: ' + DFP.Dataset_Folder_Path
                ELSE CASE
                        WHEN DA.AS_instrument_data_purged > 0 THEN 'Raw Data Purged: ' + DFP.Dataset_Folder_Path
                        ELSE DFP.Dataset_Folder_Path
                     END
                END,
            Archive_Folder_Path = CASE
                WHEN DA.MyEMSLState > 0 And DS.DS_created >= '9/17/2013' Then ''
                ELSE DFP.Archive_Folder_Path
                END,
            MyEMSL_URL = 'https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/' + Cast(DS.Dataset_ID as Varchar(9)),
            QC_Link = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE DFP.Dataset_URL + 'QC/index.html'
                END,
            QC_2D = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE DFP.Dataset_URL + J.AJ_resultsFolderName + '/'
                END,
            QC_Metric_Stats = CASE
                WHEN Experiment_Num LIKE 'QC[_]Shew%' THEN
                        'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/' + Inst.IN_Name + '/filterDS/QC_Shew'
                WHEN Experiment_Num LIKE 'TEDDY[_]DISCOVERY%' THEN
                        'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/qcart/inst/' + Inst.IN_Name + '/filterDS/TEDDY_DISCOVERY'
                ELSE 'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/MS2_Count/inst/' + Inst.IN_Name + '/filterDS/' + SUBSTRING(DS.Dataset_Num, 1, 4)
                END,
            UpdateRequired = 0,
            Last_Affected = GetDate()
        FROM T_Dataset DS
             INNER JOIN T_Cached_Dataset_Links DL
               ON DL.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Cached_Dataset_Folder_Paths DFP
               ON DFP.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Experiments E
               ON E.Exp_ID = DS.Exp_ID
             INNER JOIN T_Instrument_Name Inst
               ON Inst.Instrument_ID = DS.DS_instrument_name_ID
             LEFT OUTER JOIN T_Analysis_Job J
               ON DS.DeconTools_Job_for_QC = J.AJ_jobID
             LEFT OUTER JOIN T_Dataset_Archive DA
                             INNER JOIN T_Archive_Path AP
                               ON DA.AS_storage_path_ID = AP.AP_path_ID
               ON DS.Dataset_ID = DA.AS_Dataset_ID
        WHERE DL.UpdateRequired = 1
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End
    Else
    Begin
        -- @processingMode is 3
        If @showDebug > 0
        Begin
            If @datasetBatchSize > 0
                Print 'Updating cached paths for all rows in T_Cached_Dataset_Links, processing ' + Cast(@datasetBatchSize As Varchar(12)) + ' datasets at a time'
            Else
                Print 'Updating cached paths for all rows in T_Cached_Dataset_Links; note that batch size is 0, which should never be the case'
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
            MERGE T_Cached_Dataset_Links as target
            USING (
                SELECT DS.Dataset_ID,
                       DFP.DS_RowVersion,
                       DFP.SPath_RowVersion,
                       CASE
                        WHEN DA.AS_state_ID = 4 THEN 'Purged: ' + DFP.Dataset_Folder_Path
                        ELSE CASE
                                WHEN DA.AS_instrument_data_purged > 0 THEN 'Raw Data Purged: ' + DFP.Dataset_Folder_Path
                                ELSE DFP.Dataset_Folder_Path
                            END
                        END AS Dataset_Folder_Path,
                       CASE
                        WHEN DA.MyEMSLState > 0 And DS.DS_created >= '9/17/2013' Then ''
                        ELSE DFP.Archive_Folder_Path
                        END AS Archive_Folder_Path,
                       'https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/' + Cast(DS.Dataset_ID as Varchar(9)) AS MyEMSL_URL,
                       CASE
                        WHEN DA.QC_Data_Purged > 0 THEN ''
                        ELSE DFP.Dataset_URL + 'QC/index.html'
                        END AS QC_Link,
                       CASE
                        WHEN DA.QC_Data_Purged > 0 THEN ''
                        ELSE DFP.Dataset_URL + J.AJ_resultsFolderName + '/'
                        END AS QC_2D,
                       CASE
                        WHEN Experiment_Num LIKE 'QC[_]Shew%' THEN
                                'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/' + Inst.IN_Name + '/filterDS/QC_Shew'
                        WHEN Experiment_Num LIKE 'TEDDY[_]DISCOVERY%' THEN
                                'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/qcart/inst/' + Inst.IN_Name + '/filterDS/TEDDY_DISCOVERY'
                        ELSE 'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/MS2_Count/inst/' + Inst.IN_Name + '/filterDS/' + SUBSTRING(DS.Dataset_Num, 1, 4)
                        END AS QC_Metric_Stats
                FROM T_Dataset DS
                    INNER JOIN T_Cached_Dataset_Links DL
                      ON DL.Dataset_ID = DS.Dataset_ID
                    INNER JOIN T_Cached_Dataset_Folder_Paths DFP
                      ON DFP.Dataset_ID = DS.Dataset_ID
                    INNER JOIN T_Experiments E
                      ON E.Exp_ID = DS.Exp_ID
                    INNER JOIN T_Instrument_Name Inst
                      ON Inst.Instrument_ID = DS.DS_instrument_name_ID
                    LEFT OUTER JOIN T_Analysis_Job J
                      ON DS.DeconTools_Job_for_QC = J.AJ_jobID
                    LEFT OUTER JOIN T_Dataset_Archive DA
                                    INNER JOIN T_Archive_Path AP
                                      ON DA.AS_storage_path_ID = AP.AP_path_ID
                      ON DS.Dataset_ID = DA.AS_Dataset_ID
                WHERE DS.Dataset_ID BETWEEN @datasetIdStart AND @datasetIdEnd
            ) AS Source (Dataset_ID, DS_RowVersion, SPath_RowVersion, Dataset_Folder_Path, Archive_Folder_Path, MyEMSL_URL, QC_Link, QC_2D, QC_Metric_Stats)
            ON (target.Dataset_ID = source.Dataset_ID)
            WHEN Matched AND
                            (   target.DS_RowVersion <> source.DS_RowVersion OR
                                target.SPath_RowVersion <> source.SPath_RowVersion OR
                                IsNull(target.Dataset_Folder_Path, '') <> IsNull(source.Dataset_Folder_Path, '') OR
                                IsNull(target.Archive_Folder_Path, '') <> IsNull(source.Archive_Folder_Path, '') OR
                                IsNull(target.MyEMSL_URL, '') <> IsNull(source.MyEMSL_URL, '') Or
                                IsNull(target.QC_Link, '') <> IsNull(source.QC_Link, '') OR
                                IsNull(target.QC_2D, '') <> IsNull(source.QC_2D, '') OR
                                IsNull(target.QC_Metric_Stats, '') <> IsNull(source.QC_Metric_Stats, '')
                            )
            THEN UPDATE
                 Set DS_RowVersion = source.DS_RowVersion,
                     SPath_RowVersion = source.SPath_RowVersion,
                     Dataset_Folder_Path = source.Dataset_Folder_Path,
                     Archive_Folder_Path = source.Archive_Folder_Path,
                     MyEMSL_URL = source.MyEMSL_URL,
                     QC_Link = source.QC_Link,
                     QC_2D = source.QC_2D,
                     QC_Metric_Stats = source.QC_Metric_Stats,
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
        Set @message = dbo.append_to_text(@message,
                                        'Updated ' + Convert(varchar(12), @myRowCount) + dbo.check_plural(@myRowCount, ' row', ' rows') + ' in T_Cached_Dataset_Links',
                                        0, '; ', 512)

        -- Exec post_log_entry 'Debug', @message, 'update_cached_dataset_links'
    End

Done:
    return @myError

GO
