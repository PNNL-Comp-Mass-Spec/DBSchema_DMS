/****** Object:  StoredProcedure [dbo].[update_cached_dataset_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_dataset_stats]
/****************************************************
**
**  Desc:
**      Update job counts in T_Cached_Dataset_Stats, which is used by the dataset detail report view (V_Dataset_Detail_Report_Ex)
**
**      This procedure does not update cached instrument info for existing rows in T_Cached_Dataset_Stats
**      - Use procedure update_cached_dataset_instruments to update the cached instrument name and ID
**
**  Arguments:
**    @processingMode   Processing mode:
**                      0 to only process new datasets and datasets with Update_Required = 1
**                      1 to process new datasets, those with Update_Required = 1, and the 10,000 most recent datasets in DMS
**                      2 to re-process all of the entries in T_Cached_Dataset_Stats (this is the slowest update and will take ~20 seconds)
**    @showDebug        When true, show debug info
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/05/2024 mem - Initial version
**
*****************************************************/
(
    @processingMode tinyint = 0,        -- 0 to only process new datasets and datasets with Update_Required = 1
                                        -- 1 to process new datasets, those with Update_Required=1, and the 10,000 most recent datasets in DMS
                                        -- 2 to re-process all of the entries in T_Cached_Dataset_Stats (this is the slowest update)
    @message varchar(512) = '' output,
    @showDebug tinyint = 0
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @rowCountUpdated int = 0
    Declare @minimumDatasetID int = 0

    Declare @datasetIdStart int
    Declare @datasetIdEnd int
    Declare @datasetIdMax int
    Declare @datasetBatchSize int
    Declare @currentBatchDatasetIdStart int
    Declare @currentBatchDatasetIdEnd int

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
        FROM (SELECT TOP 10000 Dataset_ID
              FROM T_Datasets
              ORDER BY Dataset_ID DESC) LookupQ
    End

    ------------------------------------------------
    -- Add new datasets to T_Cached_Dataset_Stats
    -- Instrument name and ID are required because the columns cannot have null values
    ------------------------------------------------

    INSERT INTO T_Cached_Dataset_Stats (Dataset_ID,
                                        Instrument_ID,
                                        Instrument)
    SELECT DS.Dataset_ID,
           DS.DS_instrument_name_ID,
           InstName.IN_name
    FROM T_Dataset DS
         INNER JOIN T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
         LEFT OUTER JOIN T_Cached_Dataset_Stats CachedStats
           ON DS.Dataset_ID = CachedStats.Dataset_ID
    WHERE CachedStats.Dataset_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.check_plural(@myRowCount, 'dataset', 'dataset')

        If @showDebug > 0
        Begin
            Print @message
        End
    End

    SELECT @datasetIdMax = Max(Dataset_ID)
    FROM T_Cached_Dataset_Stats
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @datasetIdMax = 2147483647
    End

    If @processingMode >= 2 And @datasetIdMax < 2147483647
    Begin
        Set @datasetBatchSize = 50000
    End
    Else
    Begin
        Set @datasetBatchSize = 0
    End

    -- Cache the Dataset IDs to update
    CREATE TABLE #Tmp_DatasetIDs (
        Dataset_ID int NOT NULL PRIMARY KEY
    )

    If @processingMode IN (0, 1)
    Begin
        ------------------------------------------------
        -- Find datasets with Update_Required > 0
        -- If @processingMode is 1, also process the 10,000 most recent datasets, regardless of the value of Update_Required
        --
        -- Notes regarding T_Analysis_Job
        --   Trigger trig_i_AnalysisJob will set Update_Required to 1 when an analysis job is added to T_Analysis_Job
        --   Trigger trig_u_AnalysisJob will set Update_Required to 1 when the AJ_datasetID column is updated in T_Analysis_Job
        --   Trigger trig_d_AnalysisJob will set Update_Required to 1 when a job is deleted from T_Analysis_Job
        ------------------------------------------------

        If @processingMode = 0
        Begin
            INSERT INTO #Tmp_DatasetIDs (Dataset_ID)
            SELECT Dataset_ID
            FROM T_Cached_Dataset_Stats
            WHERE Update_Required > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            INSERT INTO #Tmp_DatasetIDs (Dataset_ID)
            SELECT Dataset_ID
            FROM T_Cached_Dataset_Stats
            WHERE Update_Required > 0
            UNION
            SELECT Dataset_ID
            FROM T_Dataset
            WHERE Dataset_ID >= @minimumDatasetID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If @myRowCount > 50000 And @datasetBatchSize = 0
        Begin
            Set @datasetBatchSize = 50000
        End

        If @showDebug > 0
        Begin
            Print 'Updating cached stats for ' + Cast(@myRowCount As varchar(12)) + dbo.check_plural(@myRowCount, ' row', ' rows') + ' in T_Cached_Dataset_Stats where ' +
                     CASE WHEN @processingMode = 0
                          THEN 'Update_Required is 1'
                          ELSE 'Dataset_ID >= ' + Cast(@minimumDatasetID As varchar(12)) + ' Or Update_Required is 1'
                     END
        End
    End
    Else
    Begin
        ------------------------------------------------
        -- Process all datasets in T_Cached_Dataset_Stats since @processingMode is 2
        ------------------------------------------------

        INSERT INTO #Tmp_DatasetIDs (Dataset_ID)
        SELECT Dataset_ID
        FROM T_Cached_Dataset_Stats
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @showDebug > 0
        Begin
            If @datasetBatchSize > 0
                Print 'Updating cached stats for all rows in T_Cached_Dataset_Stats, processing ' + Cast(@datasetBatchSize As varchar(12)) + ' datasets at a time'
            Else
                Print 'Updating cached stats for all rows in T_Cached_Dataset_Stats; note that batch size is 0, which should never be the case'
        End
    End

    If Not Exists (SELECT Dataset_ID FROM #Tmp_DatasetIDs)
    Begin
        If @showDebug > 0
        Begin
            Print 'Exiting, since nothing to do'
        End

        Return 0
    End

    Set @continue = 1
    Set @datasetIdStart = 0

    If @datasetBatchSize > 0
        Set @datasetIdEnd = @datasetIdStart + @datasetBatchSize - 1
    Else
        Set @datasetIdEnd = @datasetIdMax

    While @continue > 0
    Begin
        If @datasetBatchSize > 0
        Begin
            Set @currentBatchDatasetIdStart = @datasetIdStart
            Set @currentBatchDatasetIdEnd   = @datasetIdEnd

            If @showDebug > 0
            Begin
                Print 'Updating Dataset IDs ' + Cast(@datasetIdStart As varchar(12)) + ' to ' + Cast(@datasetIdEnd As varchar(12))
            End
        End
        Else
        Begin
            SELECT @currentBatchDatasetIdStart = Min(Dataset_ID),
                   @currentBatchDatasetIdEnd   = Max(Dataset_ID)
            FROM Tmp_Dataset_IDs

            If @showDebug > 0
            Begin
                Print 'Updating Dataset IDs ' + Cast(@currentBatchDatasetIdStart As varchar(12)) + ' to ' + Cast(@currentBatchDatasetIdEnd As varchar(12))
            End
        End

        ------------------------------------------------
        -- Update job counts for entries in #Tmp_DatasetIDs
        ------------------------------------------------

        UPDATE T_Cached_Dataset_Stats
        SET Job_Count     = Coalesce(StatsQ.Job_Count, 0),
            PSM_Job_Count = Coalesce(StatsQ.PSM_Job_Count, 0)
        FROM (SELECT DS.Dataset_ID,
                     JobsQ.Job_Count,
                     PSMJobsQ.PSM_Job_Count
              FROM #Tmp_DatasetIDs DS
                   LEFT OUTER JOIN (SELECT J.Dataset_ID,
                                           COUNT(J.Job) AS Job_Count
                                    FROM T_Analysis_Job J
                                    WHERE J.Dataset_ID BETWEEN @currentBatchDatasetIdStart AND @currentBatchDatasetIdEnd
                                    GROUP BY J.dataset_id
                                   ) AS JobsQ
                     ON JobsQ.Dataset_ID = DS.Dataset_ID
                   LEFT OUTER JOIN (SELECT J.Dataset_ID,
                                           COUNT(PSMs.Job) AS PSM_Job_Count
                                    FROM T_Analysis_Job_PSM_Stats PSMs
                                         INNER JOIN T_Analysis_Job J ON PSMs.Job = J.Job
                                    WHERE J.Dataset_ID BETWEEN @currentBatchDatasetIdStart AND @currentBatchDatasetIdEnd
                                    GROUP BY J.Dataset_ID
                                   ) AS PSMJobsQ
                     ON PSMJobsQ.Dataset_ID = DS.Dataset_ID
              WHERE DS.Dataset_ID BETWEEN @datasetIdStart AND @datasetIdEnd
             ) StatsQ
        WHERE T_Cached_Dataset_Stats.Dataset_ID = StatsQ.Dataset_ID AND
              (T_Cached_Dataset_Stats.Job_Count     <> Coalesce(StatsQ.Job_Count, 0) OR
               T_Cached_Dataset_Stats.PSM_Job_Count <> Coalesce(StatsQ.PSM_Job_Count, 0))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @rowCountUpdated = @rowCountUpdated + @myRowCount

        If @datasetBatchSize <= 0
        Begin
            UPDATE T_Cached_Dataset_Stats
            SET Update_Required = 0
            WHERE Update_Required > 0 AND
                  Dataset_ID IN (SELECT DS.Dataset_ID FROM #Tmp_DatasetIDs DS)

            Set @continue = 0
        End
        Else
        Begin
            UPDATE T_Cached_Dataset_Stats
            SET Update_Required = 0
            WHERE Update_Required > 0 AND
                  Dataset_ID IN (SELECT DS.Dataset_ID
                             FROM #Tmp_DatasetIDs DS
                             WHERE DS.Dataset_ID BETWEEN @datasetIdStart AND @datasetIdEnd)

            Set @datasetIdStart = @datasetIdStart + @datasetBatchSize
            Set @datasetIdEnd   = @datasetIdEnd   + @datasetBatchSize

            If @datasetIdStart > @datasetIdMax
            Begin
                Set @continue = 0
            End
        End

    End

    If @rowCountUpdated > 0
    Begin
        Set @message = dbo.append_to_text(@message,
                                          'Updated ' + Convert(varchar(12), @rowCountUpdated) + dbo.check_plural(@rowCountUpdated, ' row', ' rows') + ' in T_Cached_Dataset_Stats',
                                          0, '; ', 512)
    End

Done:
    Return @myError

GO
