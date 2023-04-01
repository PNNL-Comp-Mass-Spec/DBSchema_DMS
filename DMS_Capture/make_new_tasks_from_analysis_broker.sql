/****** Object:  StoredProcedure [dbo].[make_new_jobs_from_analysis_broker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_new_jobs_from_analysis_broker]
/****************************************************
**
**  Desc:
**    Create new jobs from analysis job broker jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/11/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/15/2010 dac - Changed default values of @bypassDatasetArchive amd @onlyDMSArchiveUpdateReqdDatasets (production db only)
**          01/20/2010 mem - Added indices on #AUJobs
**          01/21/2010 mem - Added parameters @DatasetIDFilterMin and @DatasetIDFilterMax
**          01/25/2010 dac - Changed default @onlyDMSArchiveUpdateReqdDatasets value to 0. Parameter no longer needed
**          01/28/2010 grk - added time window for No_Dataset_Archive (only applies to recently completed jobs)
**          02/02/2010 dac - mods to get defaults input params from database table (in progress)
**          03/15/2010 mem - Now excluding rows from the source view where Input_Folder_Name is Null
**          06/04/2010 dac - Excluding rows where there are any existing jobs that are not in state 3 (complete)
**          05/05/2011 mem - Removed @onlyDMSArchiveUpdateReqdDatasets since it was only required for a short while after we switched over to the DMS_Capture DB in January 2010
**                         - Now using T_Default_SP_Params to get default input params from database table
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @infoOnly tinyint = NULL,                                   -- 0 To perform the update, 1 to preview capture tasks that would be created
    @message varchar(512)='' output,
    @importWindowDays INT = NULL,                               -- Default to 10 (via T_Default_SP_Params)
    @loggingEnabled TINYINT = NULL,
    @bypassDatasetArchive TINYINT = NULL,                       -- waive the requirement that there be an existing complete dataset archive job in broker; default to 1 (via T_Default_SP_Params)
    @datasetIDFilterMin int = NULL,                             -- If non-zero, then will be used to filter the candidate datasets
    @datasetIDFilterMax int = NULL,                             -- If non-zero, then will be used to filter the candidate datasets
    @infoOnlyShowsNewJobsOnly tinyint = 0,                      -- Set to 1 to only see new jobs that would trigger new capture tasks; only used if @infoOnly is non-zero
    @timeWindowToRequireExisingDatasetArchiveJob INT = NULL     -- Default to 30 days (via T_Default_SP_Params)
)
AS
    Set nocount on

    declare @myError int
    declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    -- Set SP name
    declare @spName varchar(128)
    SET @spName = 'make_new_jobs_from_analysis_broker'

    ---------------------------------------------------
    -- Create a temporary table containing defaults for this SP
    ---------------------------------------------------

    CREATE TABLE #Defaults( ParamName varchar(128), ParamValue VARCHAR(128) )

    INSERT INTO #Defaults( ParamName, ParamValue )
    SELECT ParamName, ParamValue
    FROM dbo.T_Default_SP_Params
    WHERE SP_Name = @spName


    ---------------------------------------------------
    -- Check input params; replace with values from temp table if any are null
    ---------------------------------------------------

    -- @ImportWindowDays
    SET @ImportWindowDays = ISNULL(@ImportWindowDays, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'importWindowDays'))

    -- @LoggingEnabled
    SET @LoggingEnabled = ISNULL(@LoggingEnabled, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'loggingEnabled'))

    -- @bypassDatasetArchive
    SET @bypassDatasetArchive = ISNULL(@bypassDatasetArchive, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'bypassDatasetArchive'))

    -- @DatasetIDFilterMin
    SET @DatasetIDFilterMin = ISNULL(@DatasetIDFilterMin, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'datasetIDFilterMin'))

    -- @DatasetIDFilterMax
    SET @DatasetIDFilterMax = ISNULL(@DatasetIDFilterMax, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'datasetIDFilterMax'))

    -- @timeWindowToRequireExisingDatasetArchiveJob
    SET @timeWindowToRequireExisingDatasetArchiveJob = ISNULL(@timeWindowToRequireExisingDatasetArchiveJob, (SELECT ParamValue FROM #Defaults WHERE ParamName = 'timeWindowToRequireExisingDatasetArchiveJob'))

    ---------------------------------------------------
    -- Create a temporary table to hold jobs from the analysis broker
    ---------------------------------------------------

    CREATE TABLE #AUJobs (
        Dataset varchar(128),
        Dataset_ID int,
        Results_Folder_Name varchar(128),
        AJ_Finish DATETIME,
        No_Dataset_Archive TINYINT,
        Pending_Archive_Update TINYINT,
        Archive_Update_Current TINYINT
    )

    CREATE CLUSTERED INDEX #IX_AUJobs_DatasetID ON #AUJobs (Dataset_ID)
    CREATE NONCLUSTERED INDEX #IX_AUJobs_ResultsFolder ON #AUJobs (Results_Folder_Name)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    Set @ImportWindowDays = IsNull(@ImportWindowDays, 10)
    If @ImportWindowDays < 1
        Set @ImportWindowDays = 1

    Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
    Set @bypassDatasetArchive = IsNull(@bypassDatasetArchive, 1)
    Set @DatasetIDFilterMin = IsNull(@DatasetIDFilterMin, 0)
    Set @DatasetIDFilterMax = IsNull(@DatasetIDFilterMax, 0)
    Set @InfoOnlyShowsNewJobsOnly = IsNull(@InfoOnlyShowsNewJobsOnly, 0)

    Set @timeWindowToRequireExisingDatasetArchiveJob = IsNull(@timeWindowToRequireExisingDatasetArchiveJob, 30)
    If @timeWindowToRequireExisingDatasetArchiveJob < 1
        Set @timeWindowToRequireExisingDatasetArchiveJob = 1


    ---------------------------------------------------
    -- get sucessfully completed results transfer steps
    -- from analysis broker with a completion date
    -- within the number of days in the import window
    ---------------------------------------------------
    --
    INSERT INTO #AUJobs (
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        AJ_Finish,
        No_Dataset_Archive,
        Pending_Archive_Update,
        Archive_Update_Current
    )
    SELECT Dataset,
           Dataset_ID,
           Input_Folder_Name,
           Finish,
           0 AS No_Dataset_Archive,
           0 AS Pending_Archive_Update,
           0 AS Archive_Update_Current
    FROM V_DMS_Pipeline_Get_Completed_Results_Transfer AS TS
    WHERE NOT Input_Folder_Name IS NULL AND
          Finish > DateAdd(day, -@ImportWindowDays, GetDate())
    ORDER BY Finish DESC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to import completed results transfer steps from analysis job broker'
        goto Done
    end

    If @DatasetIDFilterMin > 0
        DELETE FROM #AUJobs
        WHERE Dataset_ID < @DatasetIDFilterMin

    If @DatasetIDFilterMax > 0
        DELETE FROM #AUJobs
        WHERE Dataset_ID > @DatasetIDFilterMax


    ---------------------------------------------------
    -- FUTURE: There could be more than one analysis
    -- job broker database
    ---------------------------------------------------

    ---------------------------------------------------
    -- Find analysis jobs that have a recent finish time
    -- that falls within the @timeWindowToRequireExisingDatasetArchiveJob
    --
    -- For these, mark any for which there is not
    -- a completed DatasetArchive job for the dataset
    --
    -- If @bypassDatasetArchive = 1, then the value of No_Dataset_Archive will be ignored
    ---------------------------------------------------
    --
    UPDATE #AUJobs
    SET No_Dataset_Archive = 1
    WHERE #AUJobs.AJ_Finish >= DATEADD(dd, -1 * @timeWindowToRequireExisingDatasetArchiveJob, GETDATE()) AND
          NOT EXISTS ( SELECT Dataset_ID
                       FROM T_Tasks
                       WHERE (Script = 'DatasetArchive') AND
                             (State = 3) AND
                             (T_Tasks.Dataset_ID = #AUJobs.Dataset_ID)
                     )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to remove entries for which there is not a completed DatasetArchive job for the dataset'
        goto Done
    end

    ---------------------------------------------------
    -- mark entries for which there is an existing ArchiveUpdate job
    -- for the same results folder that has state <> 3
    ---------------------------------------------------
    --
    UPDATE #AUJobs
    SET Pending_Archive_Update = 1
    WHERE
    EXISTS (
        SELECT Dataset
        FROM T_Tasks
        WHERE (Script = 'ArchiveUpdate') AND
              (T_Tasks.Dataset_ID = #AUJobs.Dataset_ID) AND
              (ISNULL(T_Tasks.Results_Folder_Name, '') = #AUJobs.Results_Folder_Name) AND
              (State <> 3)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to remove entries for which there is a later existing ArchiveUpdate step'
        goto Done
    end

    ---------------------------------------------------
    -- mark entries for which there is an existing ArchiveUpdate
    -- for the same results folder that is complete
    -- with a finsh date later than the analysis broker's
    -- job step's finish date
    ---------------------------------------------------
    --
    UPDATE #AUJobs
    SET Archive_Update_Current = 1
    WHERE
    EXISTS (
        SELECT Dataset
        FROM T_Tasks
        WHERE (Script = 'ArchiveUpdate') AND
              (T_Tasks.Dataset_ID = #AUJobs.Dataset_ID) AND
              (ISNULL(T_Tasks.Results_Folder_Name, '') = #AUJobs.Results_Folder_Name) AND
              (State = 3) AND
              (T_Tasks.Finish > #AUJobs.AJ_Finish)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to remove entries for which there is a later existing ArchiveUpdate step'
        goto Done
    end

    IF @infoOnly <> 0
    BEGIN
        SELECT *
        FROM ( SELECT CONVERT(char(14), Dataset_ID) AS D_ID,
                      CONVERT(char(14), No_Dataset_Archive) AS No_Dataset_Archive,
                      CONVERT(char(14), Pending_Archive_Update) AS Pending_Archive_Update,
                      CONVERT(char(14), Archive_Update_Current) AS Archive_Update_Current,
                      CASE
                          WHEN (No_Dataset_Archive = 0 OR @bypassDatasetArchive > 0) AND
                               Pending_Archive_Update = 0 AND
                               Archive_Update_Current = 0
                          THEN 'Yes'
                          ELSE 'No'
                      END AS Capture_Task_Needed,
                      Dataset
               FROM #AUJobs
               ) LookupQ
        WHERE @InfoOnlyShowsNewJobsOnly = 0 OR
              Capture_Task_Needed = 'Yes'
        ORDER BY D_ID

    END
    Else
    Begin
        ---------------------------------------------------
        -- create new ArchiveUpdate capture jobs from
        -- remaining imported
        -- analysis broker results transfer steps
        ---------------------------------------------------
        --
        INSERT INTO T_Tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT DISTINCT 'ArchiveUpdate' AS Script,
                        Dataset,
                        Dataset_ID,
                        Results_Folder_Name,
                        'Created from broker import' AS COMMENT
        FROM #AUJobs
        WHERE ((No_Dataset_Archive = 0) OR
               (@bypassDatasetArchive > 0)) AND
              Pending_Archive_Update = 0 AND
              Archive_Update_Current = 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to add new ArchiveUpdate steps'
            goto Done
        end
    END

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    If @LoggingEnabled = 1 AND @myError > 0 AND @message <> ''
    Begin
        exec post_log_entry 'Error', @message, 'make_new_jobs_from_analysis_broker'
    End

GO
GRANT VIEW DEFINITION ON [dbo].[make_new_jobs_from_analysis_broker] TO [DDL_Viewer] AS [dbo]
GO
