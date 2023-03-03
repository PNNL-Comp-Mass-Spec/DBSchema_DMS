/****** Object:  StoredProcedure [dbo].[add_missing_predefined_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_missing_predefined_jobs]
/****************************************************
**
**  Desc:   Looks for Datasets that don't have predefined analysis jobs
**          but possibly should.  Calls schedule_predefined_analysis_jobs for each.
**          This procedure is intended to be run once per day to add missing jobs
**          for datasets created within the last 30 days (but more than 12 hours ago).
**
**  Auth:   mem
**  Date:   05/23/2008 mem - Ticket #675
**          10/30/2008 mem - Updated to only create jobs for datasets in state 3=Complete
**          05/14/2009 mem - Added parameters @analysisToolNameFilter and @excludeDatasetsNotReleased
**          10/25/2010 mem - Added parameter @datasetNameIgnoreExistingJobs
**          11/18/2010 mem - Now skipping datasets with a rating of -6 (Rerun, good data) when @excludeDatasetsNotReleased is non-zero
**          02/10/2011 mem - Added parameters @excludeUnreviewedDatasets and @instrumentSkipList
**          05/24/2011 mem - Added parameter @ignoreJobsCreatedBeforeDisposition
**                         - Added support for rating -7
**          08/05/2013 mem - Now passing @analysisToolNameFilter to evaluate_predefined_analysis_rules when @infoOnly is non-zero
**                         - Added parameter @campaignFilter
**          01/08/2014 mem - Now returning additional debug information when @infoOnly > 0
**          06/18/2014 mem - Now passing default to parse_delimited_list
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/03/2017 mem - Exclude datasets associated with the Tracking experiment
**                         - Exclude datasets of type Tracking
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list
**          03/25/2020 mem - Add parameter @datasetIDFilterList and add support for @infoOnly = 2
**          11/28/2022 mem - Always log an error if schedule_predefined_analysis_jobs has a non-zero return code
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @infoOnly tinyint = 0,                                      -- 0 to create jobs, 1 to preview jobs that would be created, 2 include additional debug information
    @maxDatasetsToProcess int = 0,
    @dayCountForRecentDatasets int = 30,                        -- Will examine datasets created within this many days of the present
    @previewOutputType varchar(12) = 'Show Jobs',               -- Used if @infoOnly = 1; options are 'Show Rules' or 'Show Jobs'
    @analysisToolNameFilter varchar(128) = '',                  -- Optional: if not blank, only considers predefines and jobs that match the given tool name (can contain wildcards)
    @excludeDatasetsNotReleased tinyint = 1,                    -- When non-zero, excludes datasets with a rating of -5, -6, or -7 (we always exclude datasets with a rating of -1, and -2)
    @excludeUnreviewedDatasets tinyint = 1,                     -- When non-zero, excludes datasets with a rating of -10
    @instrumentSkipList varchar(1024) = 'Agilent_GC_MS_01, TSQ_1, TSQ_3',        -- Comma-separated list of instruments to skip
    @message varchar(512) = '' output,
    @datasetNameIgnoreExistingJobs varchar(128) = '',           -- If defined, we'll create predefined jobs for this dataset even if it has existing jobs
    @ignoreJobsCreatedBeforeDisposition tinyint = 1,            -- When non-zero, ignore jobs created before the dataset was dispositioned
    @campaignFilter varchar(128) = '',                          -- Optional: if not blank, filters on the given campaign name
    @datasetIDFilterList varchar(1024) = ''                     -- Comma-separated list of Dataset IDs to process
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError INT = 0
    Declare @myRowCount INT = 0

    Declare @continue tinyint
    Declare @datasetsProcessed int
    Declare @datasetsWithNewJobs int

    Declare @entryID int
    Declare @datasetID int
    Declare @datasetName varchar(256)

    Declare @jobCountAdded int
    Declare @startDate datetime

    Declare @callingProcName varchar(128)
    Declare @currentLocation varchar(128)
    Set @currentLocation = 'Start'

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @maxDatasetsToProcess = IsNull(@maxDatasetsToProcess, 0)
    Set @dayCountForRecentDatasets = IsNull(@dayCountForRecentDatasets, 30)
    Set @previewOutputType = IsNull(@previewOutputType, 'Show Rules')
    Set @analysisToolNameFilter = IsNull(@analysisToolNameFilter, '')
    Set @excludeDatasetsNotReleased = IsNull(@excludeDatasetsNotReleased, 1)
    Set @excludeUnreviewedDatasets = IsNull(@excludeUnreviewedDatasets, 1)
    Set @instrumentSkipList = IsNull(@instrumentSkipList, '')
    set @message = ''
    Set @datasetNameIgnoreExistingJobs = IsNull(@datasetNameIgnoreExistingJobs, '')
    Set @ignoreJobsCreatedBeforeDisposition = IsNull(@ignoreJobsCreatedBeforeDisposition, 1)
    Set @campaignFilter = IsNull(@campaignFilter, '')
    Set @datasetIDFilterList = IsNull(@datasetIDFilterList, '')

    If @dayCountForRecentDatasets < 1
    Begin
        Set @dayCountForRecentDatasets = 1
    End

    If @infoOnly <> 0 And (Not @previewOutputType IN ('Show Rules', 'Show Jobs'))
    Begin
        set @message = 'Unknown value for @previewOutputType (' + @previewOutputType + '); should be "Show Rules" or "Show Jobs"'

        SELECT @message as Message

        set @myError = 51001
        Goto Done
    End

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TABLE #Tmp_DatasetsToProcess (
        Entry_ID int NOT NULL Identity(1,1),
        Dataset_ID int NOT NULL,
        Process_Dataset tinyint
    )

    CREATE TABLE #TmpDSRatingExclusionList (
        Rating int
    )

    CREATE TABLE #TmpDatasetIDFilterList (
        Dataset_ID int
    )

    -- Populate #TmpDSRatingExclusionList
    INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-1)        -- No Data (Blank/Bad)
    INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-2)        -- Data Files Missing

    If @excludeUnreviewedDatasets <> 0
    Begin
        INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-10)        -- Unreviewed
    END

    If @excludeDatasetsNotReleased <> 0
    Begin
        INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-5)    -- Not Released
        INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-6)    -- Rerun (Good Data)
        INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-7)    -- Rerun (Superseded)
    End

    IF LEN(@datasetIDFilterList) > 0
    BEGIN
        INSERT INTO #TmpDatasetIDFilterList (Dataset_ID)
        SELECT Value
        FROM dbo.parse_delimited_integer_list(@datasetIDFilterList, ',')
    END

    ---------------------------------------------------
    -- Find datasets that were created within the last @dayCountForRecentDatasets days
    -- (but over 12 hours ago) that do not have analysis jobs
    -- Also excludes datasets with an undesired state or undesired rating
    -- Optionally only matches analysis tools with names matching @analysisToolNameFilter
    ---------------------------------------------------
    --
    -- First construct a list of all recent datasets that have an instrument class
    -- that has an active predefined job
    -- Optionally filter on campaign
    --
    INSERT INTO #Tmp_DatasetsToProcess( Dataset_ID, Process_Dataset )
    SELECT DISTINCT DS.Dataset_ID, 1 AS Process_Dataset
    FROM T_Dataset DS
         INNER JOIN T_Dataset_Type_Name DSType
           ON DSType.DST_Type_ID = DS.DS_type_ID
         INNER JOIN T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
         INNER JOIN T_Experiments E
           ON DS.Exp_ID = E.Exp_ID
         INNER JOIN T_Campaign C
           ON E.EX_campaign_ID = C.Campaign_ID
    WHERE (NOT DS.DS_rating IN (SELECT Rating FROM #TmpDSRatingExclusionList)) AND
          (DS.DS_state_ID = 3) AND
          (@campaignFilter = '' Or C.Campaign_Num Like @campaignFilter) AND
          (NOT DSType.DST_name IN ('Tracking')) AND
          (NOT E.Experiment_Num in ('Tracking')) AND
          (DS.DS_created BETWEEN DATEADD(day, -@dayCountForRecentDatasets, GETDATE()) AND
                                 DATEADD(hour, -12, GETDATE())) AND
          InstName.IN_Class IN ( SELECT DISTINCT InstClass.IN_class
                                 FROM T_Predefined_Analysis PA
                                      INNER JOIN T_Instrument_Class InstClass
                                        ON PA.AD_instrumentClassCriteria = InstClass.IN_class
                                 WHERE (PA.AD_enabled <> 0) AND
                                       (@analysisToolNameFilter = '' OR
                                        PA.AD_analysisToolName LIKE @analysisToolNameFilter) )
    ORDER BY DS.Dataset_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error populating #Tmp_DatasetsToProcess'
        Goto Done
    End

    IF @infoOnly > 1 AND EXISTS (SELECT * FROM #TmpDatasetIDFilterList)
    Begin
        SELECT 'Debug_Output #1' AS Status,
               InstName.IN_name,
               DS.Dataset_ID,
               DS.Dataset_Num,
               DS.DS_created,
               DS.DS_comment,
               DS.DS_state_ID,
               DS.DS_rating,
               DTP.Process_Dataset
        FROM #Tmp_DatasetsToProcess DTP
             INNER JOIN T_Dataset DS
               ON DTP.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Instrument_Name InstName
               ON DS.DS_instrument_name_ID = InstName.Instrument_ID
             INNER JOIN #TmpDatasetIDFilterList FilterList
               ON FilterList.Dataset_ID = DTP.Dataset_ID
        ORDER BY DS.Dataset_ID
    End

    -- Now exclude any datasets that have analysis jobs in T_Analysis_Job
    -- Filter on @analysisToolNameFilter if not empty
    --
    UPDATE #Tmp_DatasetsToProcess
    Set Process_Dataset = 0
    FROM #Tmp_DatasetsToProcess DTP
         INNER JOIN ( SELECT AJ.AJ_datasetID AS Dataset_ID
                      FROM T_Analysis_Job AJ
                           INNER JOIN T_Analysis_Tool Tool
                             ON AJ.AJ_analysisToolID = Tool.AJT_toolID
                      WHERE (@analysisToolNameFilter = '' OR Tool.AJT_toolName LIKE @analysisToolNameFilter) AND
                            (@ignoreJobsCreatedBeforeDisposition = 0 OR AJ.AJ_DatasetUnreviewed = 0 )
                     ) JL
           ON DTP.Dataset_ID = JL.Dataset_ID
    WHERE DTP.Process_Dataset > 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    BEGIN
        Set @message = 'Error setting Process_Dataset to 0 in #Tmp_DatasetsToProcess for datasets that have existing jobs'
        Goto Done
    END

    IF @infoOnly > 1 AND EXISTS (SELECT * FROM #TmpDatasetIDFilterList)
    Begin
        SELECT 'Debug_Output #2' AS Status,
               InstName.IN_name,
               DS.Dataset_ID,
               DS.Dataset_Num,
               DS.DS_created,
               DS.DS_comment,
               DS.DS_state_ID,
               DS.DS_rating,
               DTP.Process_Dataset
        FROM #Tmp_DatasetsToProcess DTP
             INNER JOIN T_Dataset DS
               ON DTP.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Instrument_Name InstName
               ON DS.DS_instrument_name_ID = InstName.Instrument_ID
             INNER JOIN #TmpDatasetIDFilterList FilterList
               ON FilterList.Dataset_ID = DTP.Dataset_ID
        ORDER BY DS.Dataset_ID
    End

    -- Next, exclude any datasets that have been processed by schedule_predefined_analysis_jobs
    -- This check also compares the dataset's current rating to the rating it had when previously processed
    --
    UPDATE #Tmp_DatasetsToProcess
    Set Process_Dataset = 0
    FROM #Tmp_DatasetsToProcess DTP INNER JOIN
         T_Dataset DS ON DTP.Dataset_ID =DS.Dataset_ID INNER JOIN
         T_Predefined_Analysis_Scheduling_Queue_History QH
         ON DS.Dataset_ID = QH.Dataset_ID AND DS.DS_rating = QH.DS_rating
    WHERE DTP.Process_Dataset > 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error setting Process_Dataset to 0 in #Tmp_DatasetsToProcess for datasets in T_Predefined_Analysis_Scheduling_Queue_History'
        Goto Done
    END

    IF @infoOnly > 1 AND EXISTS (SELECT * FROM #TmpDatasetIDFilterList)
    Begin
        SELECT 'Debug_Output #3' AS Status,
               InstName.IN_name,
               DS.Dataset_ID,
               DS.Dataset_Num,
               DS.DS_created,
               DS.DS_comment,
               DS.DS_state_ID,
               DS.DS_rating,
               DTP.Process_Dataset
        FROM #Tmp_DatasetsToProcess DTP
             INNER JOIN T_Dataset DS
               ON DTP.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Instrument_Name InstName
               ON DS.DS_instrument_name_ID = InstName.Instrument_ID
             INNER JOIN #TmpDatasetIDFilterList FilterList
               ON FilterList.Dataset_ID = DTP.Dataset_ID
        ORDER BY DS.Dataset_ID
    End

    IF EXISTS (SELECT * FROM #TmpDatasetIDFilterList)
    BEGIN
        -- Exclude datasets not in #TmpDatasetIDFilterList
        UPDATE #Tmp_DatasetsToProcess
        Set Process_Dataset = 0
        WHERE Process_Dataset > 0 And
              NOT Dataset_ID IN (SELECT Dataset_ID FROM #TmpDatasetIDFilterList)
    END

    -- Exclude datasets from instruments in @instrumentSkipList
    If @instrumentSkipList <> ''
    Begin
        UPDATE #Tmp_DatasetsToProcess
        SET Process_Dataset = 0
        FROM #Tmp_DatasetsToProcess Target
         INNER JOIN T_Dataset DS
               ON Target.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Instrument_Name InstName
             ON InstName.Instrument_ID = DS.DS_instrument_name_ID
             INNER JOIN parse_delimited_list(@instrumentSkipList, default, 'add_missing_predefined_jobs') AS ExclusionList
               ON InstName.IN_name = ExclusionList.Value
    End

    -- Add dataset @datasetNameIgnoreExistingJobs
    If @datasetNameIgnoreExistingJobs <> ''
    Begin
        UPDATE #Tmp_DatasetsToProcess
        SET Process_Dataset = 1
        FROM #Tmp_DatasetsToProcess Target
             INNER JOIN T_Dataset DS
          ON Target.Dataset_ID = DS.Dataset_ID
        WHERE DS.Dataset_Num = @datasetNameIgnoreExistingJobs
    End

    If @infoOnly <> 0
    Begin
        SELECT InstName.IN_name,
               DS.Dataset_ID,
               DS.Dataset_Num,
               DS.DS_created,
               DS.DS_comment,
               DS.DS_state_ID,
               DS.DS_rating,
               DTP.Process_Dataset
        FROM #Tmp_DatasetsToProcess DTP
             INNER JOIN T_Dataset DS
               ON DTP.Dataset_ID = DS.Dataset_ID
             INNER JOIN T_Instrument_Name InstName
               ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        WHERE DTP.Process_Dataset = 1
        ORDER BY InstName.IN_name, DS.Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        IF @infoOnly > 1
        Begin
            SELECT 'Ignored' AS Status,
                   InstName.IN_name,
                   DS.Dataset_ID,
                   DS.Dataset_Num,
                   DS.DS_created,
                   DS.DS_comment,
                   DS.DS_state_ID,
                   DS.DS_rating,
                   DTP.Process_Dataset
            FROM #Tmp_DatasetsToProcess DTP
                 INNER JOIN T_Dataset DS
                   ON DTP.Dataset_ID = DS.Dataset_ID
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            WHERE DTP.Process_Dataset = 0
            ORDER BY InstName.IN_name, DS.Dataset_ID
        End
    End

    -- Count the number of entries with Process_Dataset = 1 in #Tmp_DatasetsToProcess
    SELECT @myRowCount = COUNT(*)
    FROM #Tmp_DatasetsToProcess
    WHERE Process_Dataset = 1

    If @myRowCount = 0
    Begin
        Set @message = 'All recent (valid) datasets with potential predefined jobs already have existing analysis jobs'
        If @infoOnly <> 0
        Begin
            SELECT @message AS message
        End
    End
    Else
    Begin -- <a>

        -- Remove any extra datasets from #Tmp_DatasetsToProcess
        DELETE FROM #Tmp_DatasetsToProcess
        WHERE Process_Dataset = 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        ---------------------------------------------------
        -- Loop through the datasets in #Tmp_DatasetsToProcess
        -- Call evaluate_predefined_analysis_rules or schedule_predefined_analysis_jobs for each one
        ---------------------------------------------------

        Set @datasetsProcessed = 0
        Set @datasetsWithNewJobs = 0

        Set @entryID = 0
        Set @continue = 1

        While @continue = 1
        Begin -- <b>
            SELECT TOP 1 @entryID = DTP.Entry_ID,
                         @datasetID = DTP.Dataset_ID,
                         @datasetName = DS.Dataset_Num
            FROM #Tmp_DatasetsToProcess DTP
                 INNER JOIN T_Dataset DS
                   ON DTP.Dataset_ID = DS.Dataset_ID
            WHERE Entry_ID > @entryID
            ORDER BY Entry_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount < 1
            Begin
                Set @continue = 0
            End
            Else
            Begin -- <c>
                Begin Try

                    If @infoOnly <> 0
                    Begin
                        Set @currentLocation = 'Calling schedule_predefined_analysis_jobs for ' + @datasetName

                        Exec evaluate_predefined_analysis_rules @datasetName, @previewOutputType, @message = @message output, @excludeDatasetsNotReleased=@excludeDatasetsNotReleased, @analysisToolNameFilter=@analysisToolNameFilter
                    End


                    Set @currentLocation = 'Calling schedule_predefined_analysis_jobs for ' + @datasetName
                    Set @startDate = GetDate()

                    Exec @myError = schedule_predefined_analysis_jobs @datasetName, @analysisToolNameFilter=@analysisToolNameFilter, @excludeDatasetsNotReleased=@excludeDatasetsNotReleased, @infoOnly=@infoOnly

                    If @myError = 0 And @infoOnly = 0
                    Begin -- <e1>
                        -- See if jobs were actually added by querying T_Analysis_Job

                        Set @jobCountAdded = 0

                        SELECT @jobCountAdded = COUNT(*)
                        FROM T_Analysis_Job
                        WHERE AJ_DatasetID = @datasetID AND
                                AJ_Created >= @startDate
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @jobCountAdded > 0
                        Begin -- <f>
                            UPDATE T_Analysis_Job
                            SET AJ_Comment = IsNull(AJ_Comment, '') + ' (missed predefine)'
                            WHERE AJ_DatasetID = @datasetID AND
                                    AJ_Created >= @startDate
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            If @myRowCount <> @jobCountAdded
                            Begin
                                Set @message = 'Added ' + Convert(varchar(12), @jobCountAdded) + ' missing predefined analysis job(s) for dataset ' + @datasetName + ', but updated the comment for ' + convert(varchar(12), @myRowCount) + ' job(s); mismatch is unexpected'
                                Exec post_log_entry 'Error', @message, 'add_missing_predefined_jobs'
                            End

                            Set @message = 'Added ' + Convert(varchar(12), @jobCountAdded) + ' missing predefined analysis job'
                            If @jobCountAdded <> 1
                            Begin
                                Set @message = @message + 's'
                            End

                            Set @message = @message + ' for dataset ' + @datasetName

                            Exec post_log_entry 'Warning', @message, 'add_missing_predefined_jobs'

                            Set @datasetsWithNewJobs = @datasetsWithNewJobs + 1
                        End
                    End -- </e1>
                    Else
                    Begin -- <e2>
                        If @infoOnly = 0
                        Begin
                            Set @message = 'Error calling schedule_predefined_analysis_jobs for dataset ' + @datasetName + '; error code ' + Convert(varchar(12), @myError)
                            Exec post_log_entry 'Error', @message, 'add_missing_predefined_jobs'
                            Set @message = ''
                        End
                    End -- </e2>


                End Try
                Begin Catch
                    -- Error caught; log the error then abort processing
                    Set @callingProcName = IsNull(ERROR_PROCEDURE(), 'add_missing_predefined_jobs')
                    exec local_error_handler  @callingProcName, @currentLocation, @logError = 1,
                                            @errorNum = @myError output, @message = @message output

                End Catch

                Set @datasetsProcessed = @datasetsProcessed + 1
            End -- </c>

            If @maxDatasetsToProcess > 0 And @datasetsProcessed >= @maxDatasetsToProcess
            Begin
                Set @continue = 0
            End
        End -- </b>

        If @datasetsProcessed > 0 And @infoOnly = 0
        Begin
            Set @message = 'Added predefined analysis jobs for ' + Convert(varchar(12), @datasetsWithNewJobs) + ' dataset'
            If @datasetsWithNewJobs <> 1
            Begin
                Set @message = @message + 's'
            End

            Set @message = @message + ' (processed ' + Convert(varchar(12), @datasetsProcessed) + ' dataset'
            If @datasetsProcessed <> 1
            Begin
                Set @message = @message + 's'
            End

            Set @message = @message + ')'

            If @datasetsWithNewJobs > 0 And @infoOnly = 0
            Begin
                Exec post_log_entry 'Normal', @message, 'add_missing_predefined_jobs'
            End
        End

    End -- </a>

Done:
    return @myError

GO
GRANT EXECUTE ON [dbo].[add_missing_predefined_jobs] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_missing_predefined_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_missing_predefined_jobs] TO [Limited_Table_Write] AS [dbo]
GO
