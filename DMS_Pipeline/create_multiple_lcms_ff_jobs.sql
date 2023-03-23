/****** Object:  StoredProcedure [dbo].[create_multiple_lcms_ff_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_multiple_lcms_ff_jobs]
/****************************************************
**
**  Desc:   Creates a new LC-MS Feature Finder job for a series of existing DeconTools jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   10/27/2010 jds - Initial version
**          11/24/2010 mem - Now grabbing dataset name from T_Jobs_History (if not found in T_Jobs)
**          01/09/2012 mem - Now passing @ownerUsername to add_update_local_job_in_broker
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/22/2023 mem - Rename variable
**
*****************************************************/
(
    @jobList varchar(max),                              -- Comma separated list of DeconTools jobs to process
    @scriptName varchar(64) = 'LCMSFeature_Finder',     -- Example: LCMSFeature_Finder
    @lcmsFeatureFinderIniFile varchar(256),
    @callingUser varchar(128) = '',
    @message varchar(512)='' output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @ScriptFirst varchar(64)
    Declare @ScriptLast varchar(64)
    Declare @myError int
    Declare @myRowCount int
    Declare @refJob int
    Declare @continue tinyint
    set @myError = 0
    set @myRowCount = 0
    set @message = ''


    CREATE TABLE #Tmp_JobsToLoad (
        Job int NOT NULL,
        Valid tinyint NOT NULL,
        Script varchar(64) NULL,
        Dataset varchar(128) NULL
    )

    ---------------------------------------------------
    -- Populate a temporary table with the list of jobs
    ---------------------------------------------------
    --

    INSERT INTO #Tmp_JobsToLoad (Job, Valid)
    SELECT Value, 0
    FROM dbo.parse_delimited_integer_list(@JobList, ',')


    ---------------------------------------------------
    -- Validate that the job numbers exist in T_Jobs or T_Jobs_History
    ---------------------------------------------------
    --
    UPDATE #Tmp_JobsToLoad
    SET Valid = 1,
        Script = T_Jobs.Script,
        Dataset = T_Jobs.Dataset
    FROM #Tmp_JobsToLoad
         INNER JOIN T_Jobs
           ON #Tmp_JobsToLoad.Job = T_Jobs.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    UPDATE #Tmp_JobsToLoad
    SET Valid = 1,
        Script = T_Jobs_History.Script,
        Dataset = T_Jobs_History.Dataset
    FROM #Tmp_JobsToLoad
         INNER JOIN T_Jobs_History
           ON #Tmp_JobsToLoad.Job = T_Jobs_History.Job
    WHERE T_Jobs_History.State = 4 AND
          #Tmp_JobsToLoad.Valid <> 1
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Warn the user if any invalid jobs are present
    ---------------------------------------------------
    --
    IF EXISTS (SELECT * FROM #Tmp_JobsToLoad WHERE Valid = 0)
    Begin
        SELECT 'Invalid job (either not in T_Jobs or in T_Jobs_History but does not have state=4)', Job
        FROM #Tmp_JobsToLoad
        WHERE Valid = 0
    End

    DELETE FROM #Tmp_JobsToLoad
    WHERE Valid = 0

    If NOT EXISTS (SELECT * FROM #Tmp_JobsToLoad)
    Begin
        Set @message = 'No valid jobs'
        Set @myError = 50000
        Goto Done
    End


    ---------------------------------------------------
    -- Make sure all of the jobs used the same script
    ---------------------------------------------------
    --
    SELECT @ScriptFirst = MIN(Script),
           @ScriptLast =  MAX(Script)
    FROM #Tmp_JobsToLoad
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If IsNull(@ScriptFirst,'') <> IsNull(@ScriptLast, '')
    Begin
        Set @message = 'The jobs must all have the same script defined: ' + @ScriptFirst + ' <> ' + @ScriptLast
        Set @myError = 50001
        Goto Done
    End

    ---------------------------------------------------
    -- Loop through the jobs and call add_update_local_job_in_broker for each
    ---------------------------------------------------
    --
    Set @refJob = 0
    Set @continue = 1
    Set @myError = 0

    Declare @RC int,
            @datasetName varchar(128),
            @newJob int,
            @Job int,
            @priority int,
            @jobParam varchar(8000),
            @comment varchar(512),
            @ownerUsername varchar(64),
            @resultsFolderName varchar(128),
            @mode varchar(12)

    While @Continue = 1 And @myError = 0
    Begin
        SELECT TOP 1 @refJob = Job, @datasetName = Dataset
        FROM #Tmp_JobsToLoad
        WHERE Job > @refJob
        ORDER BY Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        IF @myRowCount = 0
            Set @Continue = 0
        Else
        Begin

            set @priority = 1
            set @jobParam = '<Param Section="JobParameters" Name="sourceJob" Value="' + convert(varchar(32), @refJob) + '" Reqd="Yes"/><Param Section="JobParameters" Name="LCMSFeatureFinderIniFile" Value="' + @LCMSFeatureFinderIniFile + '" Reqd="Yes"/>'
            set @comment = 'Automated job creation'

            set @ownerUsername = @callingUser
            If IsNull(@ownerUsername, '') = ''
                set @ownerUsername = suser_sname()

            set @resultsFolderName = @resultsFolderName
            set @mode = 'add'
            set @message = @message

            set @Job = 0

            exec @myError = add_update_local_job_in_broker
                            @Job = @Job OUTPUT,
                            @scriptName = @ScriptName,
                            @datasetName = @datasetName,
                            @priority = 1,
                            @jobParam = @jobParam,
                            @comment = 'Automatic Job creation',
                            @ownerUsername = @ownerUsername,
                            @resultsFolderName = @resultsFolderName OUTPUT,
                            @mode = 'add',
                            @message = @message OUTPUT,
                            @callingUser = @callingUser,
                            @DebugMode = @DebugMode

        End

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_multiple_lcms_ff_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_multiple_lcms_ff_jobs] TO [Limited_Table_Write] AS [dbo]
GO
