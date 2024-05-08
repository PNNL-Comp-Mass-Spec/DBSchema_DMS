/****** Object:  StoredProcedure [dbo].[update_cached_experiment_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_experiment_stats]
/****************************************************
**
**  Desc:
**      Update T_Cached_Experiment_Stats, which is used by the experiment detail report view (V_Experiment_Detail_Report_Ex)
**
**  Arguments:
**    @processingMode   Processing mode:
**                      0 to only process new experiments and experiments with Update_Required = 1
**                      1 to process new experiments, those with Update_Required = 1, and the 10,000 most recent experiments in DMS
**                      2 to re-process all of the entries in T_Cached_Experiment_Stats (this is the slowest update and will take ~20 seconds)
**    @showDebug        When true, show debug info
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/05/2024 mem - Initial version
**
*****************************************************/
(
    @processingMode tinyint = 0,        -- 0 to only process new experiments and experiments with Update_Required = 1
                                        -- 1 to process new experiments, those with Update_Required=1, and the 10,000 most recent experiments in DMS
                                        -- 2 to re-process all of the entries in T_Cached_Experiment_Stats (this is the slowest update)
    @message varchar(512) = '' output,
    @showDebug tinyint = 0
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @rowCountUpdated int = 0
    Declare @minimumExperimentID int = 0

    Declare @experimentIdStart int
    Declare @experimentIdEnd int
    Declare @experimentIdMax int
    Declare @experimentBatchSize int

    Declare @continue tinyint
    Declare @experimentId int

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @processingMode = IsNull(@processingMode, 0)
    Set @message = ''
    Set @showDebug = IsNull(@showDebug, 0)

    If @processingMode IN (0, 1)
    Begin
        SELECT @minimumExperimentID = MIN(Exp_ID)
        FROM ( SELECT TOP 10000 Exp_ID
               FROM T_Experiments
               ORDER BY Exp_ID DESC ) LookupQ
    End

    ------------------------------------------------
    -- Add new experiments to T_Cached_Experiment_Stats
    ------------------------------------------------
    --
    INSERT INTO T_Cached_Experiment_Stats (Exp_ID, Update_Required)
    SELECT E.Exp_ID, 1 AS Update_Required
    FROM T_Experiments E
         LEFT OUTER JOIN T_Cached_Experiment_Stats CES
           ON CES.Exp_ID = E.Exp_ID
    WHERE E.Exp_ID >= @minimumExperimentID AND
          CES.Exp_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.check_plural(@myRowCount, 'experiment', 'experiments')

        If @showDebug > 0
        Begin
            Print @message
        End
    End

    SELECT @experimentIdMax = Max(Exp_ID)
    FROM T_Cached_Experiment_Stats
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @experimentIdMax = 2147483647
    End

    If @processingMode >= 2 And @experimentIdMax < 2147483647
    Begin
        Set @experimentBatchSize = 50000
    End
    Else
    Begin
        Set @experimentBatchSize = 0
    End

    -- Cache the Experiment IDs to update
    CREATE TABLE #Tmp_ExperimentIDs (
        Exp_ID int NOT NULL PRIMARY KEY
    )

    If @processingMode IN (0, 1)
    Begin
        ------------------------------------------------
        -- Find experiments with Update_Required > 0
        -- If @processingMode is 1, also process the 10,000 most recent experiments, regardless of the value of update_required
        --
        -- Notes regarding T_Dataset
        --   Trigger trig_i_Dataset will set Update_Required to 1 when a dataset is added to T_Dataset
        --   Trigger trig_u_Dataset will set Update_Required to 1 when the Exp_ID column is updated in T_Dataset
        --   Trigger trig_d_Dataset will set Update_Required to 1 when a dataset is deleted from T_Dataset
        ------------------------------------------------

        If @processingMode = 0
        Begin
            INSERT INTO #Tmp_ExperimentIDs (Exp_ID)
            SELECT Exp_ID
            FROM T_Cached_Experiment_Stats
            WHERE Update_Required > 0;
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            INSERT INTO #Tmp_ExperimentIDs (Exp_ID)
            SELECT Exp_ID
            FROM T_Cached_Experiment_Stats
            WHERE Update_Required > 0
            UNION
            SELECT Exp_ID
            FROM T_Experiments
            WHERE Exp_ID >= @minimumExperimentID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If @myRowCount > 50000 And @experimentBatchSize = 0
        Begin
            Set @experimentBatchSize = 50000
        End

        If @showDebug > 0
        Begin
            Print 'Updating cached stats for ' + Cast(@myRowCount As varchar(12)) + dbo.check_plural(@myRowCount, ' row', ' rows') + ' in T_Cached_Experiment_Stats where ' +
                     CASE WHEN @processingMode = 0
                          THEN 'Update_Required is 1'
                          ELSE 'Exp_ID >= ' + Cast( @minimumExperimentID As varchar(12)) + ' Or Update_Required is 1'
                     END
        End
    End
    Else
    Begin
        ------------------------------------------------
        -- Process all experiments in T_Cached_Experiment_Stats since @processingMode is 2
        ------------------------------------------------

        INSERT INTO #Tmp_ExperimentIDs (Exp_ID)
        SELECT Exp_ID
        FROM T_Cached_Experiment_Stats;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @showDebug > 0
        Begin
            If @experimentBatchSize > 0
                Print 'Updating cached stats for all rows in T_Cached_Experiment_Stats, processing ' + Cast(@experimentBatchSize As varchar(12)) + ' experiments at a time'
            Else
                Print 'Updating cached stats for all rows in T_Cached_Experiment_Stats; note that batch size is 0, which should never be the case'
        End
    End

    If Not Exists (SELECT Exp_ID FROM #Tmp_ExperimentIDs)
    Begin
        If @showDebug > 0
        Begin
            Print 'Exiting, since nothing to do'
        End

        Return 0
    End

    Set @continue = 1
    Set @experimentIdStart = 0

    If @experimentBatchSize > 0
        Set @experimentIdEnd = @experimentIdStart + @experimentBatchSize - 1
    Else
        Set @experimentIdEnd = @experimentIdMax

    While @continue > 0
    Begin
        If @showDebug > 0
        Begin
            Print 'Updating Experiment IDs ' + Cast(@experimentIdStart As varchar(12)) + ' to ' + Cast(@experimentIdEnd As varchar(12))
        End

        ------------------------------------------------
        -- Update dataset info for entries in Tmp_ExperimentIDs
        ------------------------------------------------

        UPDATE T_Cached_Experiment_Stats
        SET Dataset_Count       = Coalesce(StatsQ.Dataset_Count, 0),
            Most_Recent_Dataset = StatsQ.Most_Recent_Dataset
        FROM ( SELECT E.Exp_ID,
                      DSCountQ.Dataset_Count,
                      DSCountQ.Most_Recent_Dataset
               FROM #Tmp_ExperimentIDs E
                    LEFT OUTER JOIN ( SELECT Exp_ID,
                                             COUNT(Dataset_ID) AS Dataset_Count,
                                             MAX(DS_Created) AS Most_Recent_Dataset
                                      FROM T_Dataset
                                      GROUP BY Exp_ID ) AS DSCountQ
                      ON DSCountQ.Exp_ID = E.Exp_ID
               WHERE E.Exp_ID BETWEEN @experimentIdStart AND @experimentIdEnd
             ) StatsQ
        WHERE T_Cached_Experiment_Stats.Exp_ID = StatsQ.Exp_ID AND
              (T_Cached_Experiment_Stats.Dataset_Count <> Coalesce(StatsQ.Dataset_Count, 0) OR
               -- Check whether T_Cached_Experiment_Stats.Most_Recent_Dataset Is Distinct From StatsQ.Most_Recent_Dataset
               Coalesce(NULLIF(T_Cached_Experiment_Stats.Most_Recent_Dataset, StatsQ.Most_Recent_Dataset),
                        NULLIF(StatsQ.Most_Recent_Dataset, T_Cached_Experiment_Stats.Most_Recent_Dataset)) IS NOT NULL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @rowCountUpdated = @rowCountUpdated + @myRowCount

        ------------------------------------------------
        -- Update factor counts for entries in Tmp_ExperimentIDs
        ------------------------------------------------

        UPDATE T_Cached_Experiment_Stats
        SET Factor_Count = Coalesce(StatsQ.Factor_Count, 0)
        FROM ( SELECT E.Exp_ID,
                      FC.Factor_Count
               FROM #Tmp_ExperimentIDs E
                    INNER JOIN V_Factor_Count_By_Experiment FC
                      ON FC.Exp_ID = E.Exp_ID
               WHERE E.Exp_ID BETWEEN @experimentIdStart AND @experimentIdEnd
             ) StatsQ
        WHERE T_Cached_Experiment_Stats.Exp_ID = StatsQ.Exp_ID AND
              T_Cached_Experiment_Stats.Factor_Count <> Coalesce(StatsQ.Factor_Count, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @rowCountUpdated = @rowCountUpdated + @myRowCount

        If @experimentBatchSize <= 0
        Begin
            UPDATE T_Cached_Experiment_Stats
            SET Update_Required = 0
            WHERE Update_Required > 0 AND
                  Exp_ID IN (SELECT E.Exp_ID FROM #Tmp_ExperimentIDs E)

            Set @continue = 0
        End
        Else
        Begin
            UPDATE T_Cached_Experiment_Stats
            SET Update_Required = 0
            WHERE Update_Required > 0 AND
                  Exp_ID IN (SELECT E.Exp_ID
                             FROM #Tmp_ExperimentIDs E
                             WHERE E.Exp_ID BETWEEN @experimentIdStart AND @experimentIdEnd)

            Set @experimentIdStart = @experimentIdStart + @experimentBatchSize
            Set @experimentIdEnd   = @experimentIdEnd   + @experimentBatchSize

            If @experimentIdStart > @experimentIdMax
            Begin
                Set @continue = 0
            End
        End

    End

    If @rowCountUpdated > 0
    Begin
        Set @message = dbo.append_to_text(@message,
                                          'Updated ' + Convert(varchar(12), @rowCountUpdated) + dbo.check_plural(@rowCountUpdated, ' row', ' rows') + ' in T_Cached_Experiment_Stats',
                                          0, '; ', 512)
    End

Done:
    Return @myError

GO
