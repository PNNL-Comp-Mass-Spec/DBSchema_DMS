/****** Object:  StoredProcedure [dbo].[store_reporter_ion_obs_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[store_reporter_ion_obs_stats]
/****************************************************
**
**  Desc: Updates the reporter ion observation stats in T_Reporter_Ion_Observation_Rates for the specified analysis job
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/30/2020 mem - Initial version
**          07/31/2020 mem - Use "WITH EXECUTE AS OWNER" to allow for inserting data into T_Reporter_Ion_Observation_Rates using sp_executesql
**                         - Without this, svc-dms reports "INSERT permission was denied"
**          08/12/2020 mem - Replace @observationStatsAll with @medianIntensitiesTopNPct
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @reporterIon varchar(64),                   -- Reporter ion name, corresponding to T_Sample_Labelling_Reporter_Ions
    @topNPct int,
    @observationStatsTopNPct varchar(4000),     -- Comma separated list of observation stats, by channel
    @medianIntensitiesTopNPct varchar(4000),    -- Comma separated list of median intensity values, by channel
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
WITH EXECUTE AS OWNER
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    DECLARE @datasetID int = 0
    DECLARE @sqlInsert varchar(4096) = ''
    DECLARE @sqlValues varchar(4096) = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @job = IsNull(@job, 0)
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    Set @topNPct = ISNULL(@topNPct, 0)
    Set @medianIntensitiesTopNPct = ISNULL(@medianIntensitiesTopNPct, '')
    Set @observationStatsTopNPct = ISNULL(@observationStatsTopNPct, '')

    ---------------------------------------------------
    -- Make sure @job is defined in T_Analysis_Job
    -- In addition, validate @datasetID
    ---------------------------------------------------

    SELECT @datasetID = AJ_DatasetID
    FROM T_Analysis_Job
    WHERE AJ_jobID = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Job not found in T_Analysis_Job: ' + CAST(@job AS varchar(19))
        return 50000
    End

    -----------------------------------------------
    -- Validate the reporter ion
    -----------------------------------------------

    IF NOT EXISTS (SELECT * FROM T_Sample_Labelling_Reporter_Ions WHERE Label = @reporterIon)
    BEGIN
        Set @message = 'Unrecognized reporter ion name: ' + @reporterIon + '; for standard reporter ion names, see https://dms2.pnl.gov/sample_label_reporter_ions/report'
        exec post_log_entry 'Error', @message, 'store_reporter_ion_obs_stats', 1
        return 50002
    END

    -----------------------------------------------
    -- Populate temporary tables with the data in @observationStatsTopNPct and @medianIntensitiesTopNPct
    -----------------------------------------------

    CREATE TABLE #TmpRepIonObsStatsTopNPct
    (
        Channel int Not Null,
        Observation_Rate varchar(2048),
        Observation_Rate_Value float Null,
    )

    CREATE TABLE #TmpRepIonIntensities
    (
        Channel int Not Null,
        Median_Intensity varchar(2048),
        Median_Intensity_Value int Null,
    )

    INSERT INTO #TmpRepIonObsStatsTopNPct (Channel, Observation_Rate)
    SELECT EntryID, Value
    FROM dbo.parse_delimited_list_ordered(@observationStatsTopNPct, ',', 0)

    INSERT INTO #TmpRepIonIntensities (Channel, Median_Intensity)
    SELECT EntryID, Value
    FROM dbo.parse_delimited_list_ordered(@medianIntensitiesTopNPct, ',', 0)

    -----------------------------------------------
    -- Construct the SQL insert statements
    -----------------------------------------------

    Set @sqlInsert = 'Insert Into T_Reporter_Ion_Observation_Rates (Job,Dataset_ID,Reporter_Ion,TopNPct'

    Set @sqlValues = 'Values (' +
        CAST(@job as varchar(19)) + ', ' +
        CAST(@datasetID as varchar(19)) + ', ' +
        '''' + @reporterIon + '''' + ', ' +
        CAST(@topNPct as varchar(19)) + ', '

    Declare @channel int = 1
    Declare @channelName varchar(16)

    Declare @rowCountObsRates int = 0
    Declare @rowCountIntensities int = 0
    Declare @continue tinyint = 1

    Declare @observationRateTopNPctText varchar(2048)
    Declare @medianIntensityText varchar(2048)

    Declare @observationRateTopNPct float
    Declare @medianIntensity int

    While @continue > 0
    Begin
        SELECT TOP 1 @observationRateTopNPctText = Observation_Rate
        FROM #TmpRepIonObsStatsTopNPct
        WHERE Channel = @channel
        --
        SELECT @myError = @@error, @rowCountObsRates = @@rowcount

        SELECT TOP 1 @medianIntensityText = Median_Intensity
        FROM #TmpRepIonIntensities
        WHERE Channel = @channel
        --
        SELECT @myError = @@error, @rowCountIntensities = @@rowcount

        If @rowCountObsRates = 0 AND @rowCountIntensities = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin
            If @rowCountObsRates = 0
            Begin
                Set @message = '@medianIntensitiesTopNPct has more values than @observationStatsTopNPct; aborting'
                return 50003
            End

            If @rowCountIntensities = 0
            Begin
                Set @message = '@observationStatsTopNPct has more values than @medianIntensitiesTopNPct; aborting'
                return 50004
            End

            -- Verify that observation rates are numeric
            Set @observationRateTopNPct = try_Cast(@observationRateTopNPctText as float)
            Set @medianIntensity = try_Cast(@medianIntensityText as int)

            If @observationRateTopNPct is Null
            Begin
                Set @message = 'Observation rate ' + @observationRateTopNPctText + ' is not numeric (#TmpRepIonObsStatsTopNPct); aborting'
                return 50005
            End

            If @medianIntensity is Null
            Begin
                Set @message = 'Intensity value ' + @medianIntensityText + ' is not an integer (#TmpRepIonIntensities); aborting'
                return 50006
            End
            -- Append the channel column names to @sqlInsert, for example:
            -- , Channel3, Channel3_Median_Intensity
            --
            Set @channelName = 'Channel' + Cast(@channel as varchar(9))
            Set @sqlInsert = @sqlInsert +  ', ' + @channelName + ', ' + @channelName + '_Median_Intensity'

            -- Append the observation rate and median intensity values
            --
            If @channel > 1
            Begin
                Set @sqlValues = @sqlValues + ', '
            End

            Set @sqlValues = @sqlValues + @observationRateTopNPctText + ', ' + @medianIntensityText

            -- Store the values (only required if @infoOnly is nonzero)
            If @infoOnly > 0
            Begin
                UPDATE #TmpRepIonObsStatsTopNPct
                SET Observation_Rate_Value = @observationRateTopNPct
                WHERE Channel = @channel

                UPDATE #TmpRepIonIntensities
                SET Median_Intensity_Value = @medianIntensity
                WHERE Channel = @channel
            End
        End

        Set @channel = @channel + 1
    End

    Set @sqlInsert = @sqlInsert + ')'
    Set @sqlValues = @sqlValues + ')'

    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT @job AS Job,
               @reporterIon AS Reporter_Ion,
               ObsStats.Channel,
               ObsStats.Observation_Rate_Value AS Observation_Rate_Value_TopNPct,
               Intensities.Median_Intensity_Value AS Median_Intensity
        FROM #TmpRepIonObsStatsTopNPct ObsStats
             INNER JOIN #TmpRepIonIntensities Intensities
               ON ObsStats.Channel = Intensities.Channel
        ORDER BY ObsStats.Channel

        Print @sqlInsert
        Print @sqlValues

        Goto Done
    End

    -----------------------------------------------
    -- Add/Update T_Reporter_Ion_Observation_Rates using dynamic SQL
    -----------------------------------------------
    --

    Declare @transName varchar(64) = 'AddUpdate_T_Reporter_Ion_Observation_Rates'

    Begin Transaction @transName

    If Exists (SELECT * FROM T_Reporter_Ion_Observation_Rates WHERE Job = @job)
    Begin
        DELETE FROM T_Reporter_Ion_Observation_Rates WHERE Job = @job
    End

    Declare @sql nvarchar(max) = @sqlInsert + ' ' + @sqlValues

    exec sys.sp_executesql @sql

    Commit Transaction @transName

    Set @message = 'Reporter Ion Observation Rates stored'

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in store_reporter_ion_obs_stats'

        Set @message = @message + '; error code = ' +  CAST(@myError AS varchar(19))

        If @infoOnly = 0
            Exec post_log_entry 'Error', @message, 'store_reporter_ion_obs_stats'
    End

    If Len(@message) > 0 AND @infoOnly <> 0
        Print @message

    Return @myError

GO
GRANT EXECUTE ON [dbo].[store_reporter_ion_obs_stats] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_reporter_ion_obs_stats] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_reporter_ion_obs_stats] TO [svc-dms] AS [dbo]
GO
