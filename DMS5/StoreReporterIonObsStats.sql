/****** Object:  StoredProcedure [dbo].[StoreReporterIonObsStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[StoreReporterIonObsStats]
/****************************************************
**
**    Desc: Updates the reporter ion observation stats in T_Reporter_Ion_Observation_Rates for the specified analysis job
**
**    Return values: 0: success, otherwise, error code
**
**    Auth: mem
**    Date: 07/30/2020 mem - Initial version
**          07/31/2020 mem - Use "WITH EXECUTE AS OWNER" to allow for inserting data into T_Reporter_Ion_Observation_Rates using sp_executesql
**                         - Without this, svc-dms reports "INSERT permission was denied"
**
*****************************************************/
(
    @job int,
    @reporterIon varchar(64),                   -- Reporter ion name, corresponding to T_Sample_Labelling_Reporter_Ions
    @topNPct int,
    @observationStatsAll varchar(4000),         -- Comma separated list of observation stats, by channel
    @observationStatsTopNPct varchar(4000),     -- Comma separated list of observation stats, by channel
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
    Set @observationStatsAll = ISNULL(@observationStatsAll, '')
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
        return 50002
    END

    -----------------------------------------------
    -- Populate a temporary table with the data in @observationStatsAll and @observationStatsTopNPct
    -----------------------------------------------
    
    CREATE TABLE #TmpRepIonObsStatsAll
    (
        Channel int Not Null,
		Observation_Rate varchar(2048),
        Observation_Rate_Value float Null,
    )
    
    CREATE TABLE #TmpRepIonObsStatsTopNPct
    (
        Channel int Not Null,
		Observation_Rate varchar(2048),
        Observation_Rate_Value float Null,
    )

    INSERT INTO #TmpRepIonObsStatsAll (Channel, Observation_Rate)
    SELECT EntryID, Value
    FROM dbo.udfParseDelimitedListOrdered(@observationStatsAll, ',', 0)

    INSERT INTO #TmpRepIonObsStatsTopNPct (Channel, Observation_Rate)
    SELECT EntryID, Value
    FROM dbo.udfParseDelimitedListOrdered(@observationStatsTopNPct, ',', 0)

    Set @sqlInsert = 'Insert Into T_Reporter_Ion_Observation_Rates (Job,Dataset_ID,Reporter_Ion,TopNPct'

    Set @sqlValues = 'Values (' +
        CAST(@job as varchar(19)) + ', ' +
        CAST(@datasetID as varchar(19)) + ', ' +
        '''' + @reporterIon + '''' + ', ' +
        CAST(@topNPct as varchar(19)) + ', '

    Declare @channel int = 1
    Declare @channelName varchar(16)

    Declare @rowCountAll int = 0
    Declare @rowCountTopNPct int = 0
    Declare @continue tinyint = 1

    Declare @observationRateAllText varchar(2048)
    Declare @observationRateTopNPctText varchar(2048)

    Declare @observationRateAll float
    Declare @observationRateTopNPct float

    While @continue > 0
    Begin
        SELECT TOP 1 @observationRateAllText = Observation_Rate
        FROM #TmpRepIonObsStatsAll
        WHERE Channel = @channel
        --
        SELECT @myError = @@error, @rowCountAll = @@rowcount

        SELECT TOP 1 @observationRateTopNPctText = Observation_Rate
        FROM #TmpRepIonObsStatsTopNPct
        WHERE Channel = @channel
        --
        SELECT @myError = @@error, @rowCountTopNPct = @@rowcount

        If @rowCountAll = 0 And @rowCountTopNPct = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin
            If @rowCountAll = 0
            Begin
                Set @message = '@observationStatsTopNPct has more values than @observationStatsAll; aborting'
                return 50004
            End

            If @rowCountTopNPct = 0
            Begin
                Set @message = '@observationStatsAll has more values than @observationStatsTopNPct; aborting'
                return 50003
            End

            -- Verify that observation rates are numeric
            Set @observationRateAll = try_Cast(@observationRateAllText as float)
            Set @observationRateTopNPct = try_Cast(@observationRateTopNPctText as float)

            If @observationRateAll is Null
            Begin
                Set @message = 'Observation rate ' + @observationRateAllText + ' is not numeric (#TmpRepIonObsStatsAll); aborting'
                return 50006
            End

            If @observationRateTopNPct is Null
            Begin
                Set @message = 'Observation rate ' + @observationRateTopNPctText + ' is not numeric (#TmpRepIonObsStatsTopNPct); aborting'
                return 50005
            End

            -- Append the channel column names to @sqlInsert, for example:
            -- , Channel3, Channel3_All
            --
            Set @channelName = 'Channel' + Cast(@channel as varchar(9))
            Set @sqlInsert = @sqlInsert + ', ' + @channelName + '_All' + ', ' + @channelName

            -- Append the observation rates
            --
            If @channel > 1
            Begin
                Set @sqlValues = @sqlValues + ', '
            End

            Set @sqlValues = @sqlValues + @observationRateAllText + ', ' + @observationRateTopNPctText

            -- Store the values (only required if @infoOnly is nonzero)
            If @infoOnly > 0
            Begin
                UPDATE #TmpRepIonObsStatsAll
                SET Observation_Rate_Value = @observationRateAll
                WHERE Channel = @channel

                UPDATE #TmpRepIonObsStatsTopNPct
                SET Observation_Rate_Value = @observationRateTopNPct
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
               TopNPct.Channel,
               StatsAll.Observation_Rate_Value AS Observation_Rate_Value_All,
               TopNPct.Observation_Rate_Value AS Observation_Rate_Value_TopNPct
        FROM #TmpRepIonObsStatsTopNPct TopNPct
             INNER JOIN #TmpRepIonObsStatsAll StatsAll
               ON TopNPct.Channel = StatsAll.Channel
        ORDER BY topNPct.Channel

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
            Set @message = 'Error in StoreReporterIonObsStats'

        Set @message = @message + '; error code = ' +  CAST(@myError AS varchar(19))

        If @infoOnly = 0
            Exec PostLogEntry 'Error', @message, 'StoreReporterIonObsStats'
    End

    If Len(@message) > 0 AND @infoOnly <> 0
        Print @message


    Return @myError

GO
GRANT EXECUTE ON [dbo].[StoreReporterIonObsStats] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreReporterIonObsStats] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreReporterIonObsStats] TO [svc-dms] AS [dbo]
GO
