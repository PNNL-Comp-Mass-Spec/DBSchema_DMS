/****** Object:  StoredProcedure [dbo].[make_local_job_in_broker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_local_job_in_broker]
/****************************************************
**
**  Desc:   Create analysis job directly in broker database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          04/13/2010 grk - Initial release
**          05/25/2010 grk - All dataset name other than 'na'
**          10/25/2010 grk - Added call to adjust_params_for_local_job
**          11/25/2010 mem - Added code to update the Dependencies column in #Job_Steps
**          05/25/2011 mem - Updated call to create_steps_for_job and removed Priority from #Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          11/14/2011 mem - Now populating column Transfer_Folder_Path in T_Jobs
**          01/09/2012 mem - Added parameter @ownerUsername
**          01/19/2012 mem - Added parameter @dataPackageID
**          02/07/2012 mem - Now validating that @dataPackageID is > 0 when @scriptName is MultiAlign_Aggregator
**          03/20/2012 mem - Now calling update_job_param_org_db_info_using_data_pkg
**          08/21/2012 mem - Now including the message text reported by create_steps_for_job if it returns an error code
**          04/10/2013 mem - Now calling alter_entered_by_user to update T_Job_Events
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/10/2021 mem - Do not call s_get_new_job_id when @debugMode is non-zero
**          10/15/2021 mem - Capitalize keywords and update whitespace
**          03/02/2022 mem - Require that data package ID is non-zero for MaxQuant and MSFragger jobs
**                         - Pass data package ID to create_signatures_for_job_steps
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**
*****************************************************/
(
    @scriptName varchar(64),
    @datasetName varchar(128) = 'na',
    @priority int,
    @jobParamXML xml,
    @comment varchar(512),
    @ownerUsername varchar(64),
    @dataPackageID int,
    @debugMode tinyint = 0,            -- When setting this to 1, you can optionally specify a job using @existingJob to view the steps that would be created for that job
    @job int OUTPUT,
    @resultsFolderName varchar(128) OUTPUT,
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(255) = ''

    Set @dataPackageID = IsNull(@dataPackageID, 0)
    Set @scriptName = LTrim(RTrim(IsNull(@scriptName, '')))
    Set @debugMode = IsNull(@debugMode, 0)

    If @dataPackageID < 0
        Set @dataPackageID = 0

    ---------------------------------------------------
    -- Create temporary tables to accumulate job steps,
    -- job step dependencies, and job parameters for jobs being created
    ---------------------------------------------------

    CREATE TABLE #Jobs (
        [Job] int NOT NULL,
        [Priority] int NULL,
        [Script] varchar(64) NULL,
        [State] int NOT NULL,
        [Dataset] varchar(128) NULL,
        [Dataset_ID] int NULL,
        [Results_Folder_Name] varchar(128) NULL
    )

    CREATE TABLE #Job_Steps (
        [Job] int NOT NULL,
        [Step] int NOT NULL,
        [Tool] varchar(64) NOT NULL,
        [CPU_Load] [smallint] NULL,
        [Memory_Usage_MB] int NULL,
        [Dependencies] tinyint NULL ,
        [Shared_Result_Version] smallint NULL,
        [Filter_Version] smallint NULL,
        [Signature] int NULL,
        [State] tinyint NULL ,
        [Input_Folder_Name] varchar(128) NULL,
        [Output_Folder_Name] varchar(128) NULL,
        [Processor] varchar(128) NULL,
        Special_Instructions varchar(128) NULL
    )

    CREATE TABLE #Job_Step_Dependencies (
        [Job] int NOT NULL,
        [Step] int NOT NULL,
        [Target_Step] int NOT NULL,
        [Condition_Test] varchar(50) NULL,
        [Test_Value] varchar(256) NULL,
        [Enable_Only] tinyint NULL
    )

    CREATE TABLE #Job_Parameters (
        [Job] int NOT NULL,
        [Parameters] xml NULL
    )

    ---------------------------------------------------
    -- Script
    ---------------------------------------------------
    --
    Declare @pXML xml
    Declare @scriptXML xml
    Declare @tag varchar(8) = 'unk'

    -- Get contents of script and tag for results folder name
    --
    SELECT @scriptXML = Contents, @tag = Results_Tag
    FROM T_Scripts
    WHERE Script = @scriptName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @myError = 50013
        Set @msg = 'Script not found in T_Scripts: ' + IsNull(@scriptName, '??')
        RAISERROR (@msg, 15, 1)
        return @myError
    End

    If @scriptXML Is Null
    Begin
        Set @myError = 50014
        Set @msg = 'Script XML not defined in the Contents field of T_Scripts for script ' + IsNull(@scriptName, '??')
        RAISERROR (@msg, 15, 1)
        return @myError
    End

    If @scriptName IN ('MultiAlign_Aggregator', 'MaxQuant_DataPkg', 'MSFragger_DataPkg') And @dataPackageID = 0
    Begin
        Set @myError = 50015
        Set @msg = '"Data Package ID" must be positive when using script ' + @scriptName
        RAISERROR (@msg, 15, 1)
        return @myError
    End

    ---------------------------------------------------
    -- Obtain new job number (if not debugging)
    ---------------------------------------------------
    --
    If @debugMode = 0
    Begin
        exec @job = s_get_new_job_id 'Created in broker'
        --
        If @job = 0
        Begin
            Set @myError = 50010
            Set @msg = 'Could not get a valid job number from DMS'
            RAISERROR (@msg, 15, 1)
            return @myError
        End
    End

    ---------------------------------------------------
    -- Note: @datasetID needs to be 0
    -- If it is non-zero, the newly created job will get deleted from
    --  this DB the next time update_context runs, since the system will think
    --  the job no-longer exists in DMS5 and thus should be deleted
    ---------------------------------------------------

    Declare @datasetID int = 0

    ---------------------------------------------------
    -- Add job to temp table
    ---------------------------------------------------
    --
    INSERT INTO #Jobs (Job, Priority, Script, State, Dataset, Dataset_ID, Results_Folder_Name)
    VALUES (@job, @priority, @scriptName, 1, @datasetName, @datasetID, NULL)

    ---------------------------------------------------
    -- Get results folder name (and store in #Jobs)
    ---------------------------------------------------
    --
    exec @myError = create_results_folder_name @job, @tag, @resultsFolderName output, @message output
    If @myError <> 0
    Begin
        Set @msg = 'Error returned by create_results_folder_name: ' + Convert(varchar(12), @myError)
        goto Done
    End

    ---------------------------------------------------
    -- Create the basic job structure (steps and dependencies)
    -- Details are stored in #Job_Steps and #Job_Step_Dependencies
    ---------------------------------------------------
    --
    exec @myError = create_steps_for_job @job, @scriptXML, @resultsFolderName, @message output
    If @myError <> 0
    Begin
        Set @msg = 'Error returned by create_steps_for_job: ' + Convert(varchar(12), @myError)
        If IsNull(@message, '') <> ''
            Set @msg = @msg + '; ' + @message
        goto Done
    End

    ---------------------------------------------------
    -- Do special needs for local jobs that target other jobs
    ---------------------------------------------------
    EXEC adjust_params_for_local_job
        @scriptName ,
        @datasetName ,
        @dataPackageID ,
        @jobParamXML OUTPUT,
        @message output

    If @debugMode > 0
    Begin
        Print ''
        Print 'Job params after calling adjust_params_for_local_job: ' + Cast(@jobParamXML As Varchar(8000))
    End

    ---------------------------------------------------
    -- Calculate signatures for steps that require them (and also handle shared results folders)
    -- Details are stored in #Job_Steps
    ---------------------------------------------------
    --
    exec @myError = create_signatures_for_job_steps @job, @jobParamXML, @dataPackageID, @message output, @debugMode = @debugMode
    If @myError <> 0
    Begin
        Set @msg = 'Error returned by create_signatures_for_job_steps: ' + Convert(varchar(12), @myError)
        goto Done
    End

    ---------------------------------------------------
    -- Save job parameters as XML into temp table
    ---------------------------------------------------
    -- FUTURE: need to get set of parameters normally provided by get_job_param_table,
    -- except for the job specifc ones which need to be provided as initial content of @jobParamXML
    --
    INSERT INTO #Job_Parameters (Job, Parameters)
    VALUES (@job, @jobParamXML)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @myError = 50012
        Set @msg = 'Error copying job param scratch to temp'
        RAISERROR (@msg, 15, 1)
        return @myError
    End

    ---------------------------------------------------
    -- Handle any step cloning
    ---------------------------------------------------
    --
    exec @myError = clone_job_step @job, @jobParamXML, @message output
    If @myError <> 0
    Begin
        Set @msg = 'Error returned by clone_job_step: ' + Convert(varchar(12), @myError)
        goto Done
    End

    ---------------------------------------------------
    -- Update step dependency count (code taken from SP finish_job_creation)
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET Dependencies = T.dependencies
    FROM #Job_Steps
         INNER JOIN ( SELECT Step,
                             COUNT(*) AS dependencies
                      FROM #Job_Step_Dependencies
                      WHERE (Job = @job)
                      GROUP BY Step ) AS T
           ON T.Step = #Job_Steps.Step
    WHERE #Job_Steps.Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating job step dependency count: ' + Convert(varchar(12), @myError)
        goto Done
    End

    ---------------------------------------------------
    -- Move temp tables to main tables
    ---------------------------------------------------

    If @debugMode = 0
    Begin
        -- move_jobs_to_main_tables sproc assumes that T_Jobs table entry is already there
        --
        INSERT INTO T_Jobs( Job,
                            Priority,
                            Script,
                            State,
                            Dataset,
                            Dataset_ID,
                            Transfer_Folder_Path,
                            [Comment],
                            Storage_Server,
                            Owner,
                            DataPkgID )
        VALUES(@job, @priority, @scriptName, 1,
               @datasetName, @datasetID, NULL,
               @comment, NULL, @ownerUsername,
               IsNull(@dataPackageID, 0))

        exec @myError = move_jobs_to_main_tables @message output

        exec alter_entered_by_user 'T_Job_Events', 'Job', @job, @callingUser
    End

    If @debugMode = 0
    Begin
        ---------------------------------------------------
        -- Populate column Transfer_Folder_Path in T_Jobs
        ---------------------------------------------------
        --
        Declare @transferFolderPath varchar(512) = ''

        SELECT @transferFolderPath = [Value]
        FROM dbo.get_job_param_table_local ( @job )
        WHERE [Name] = 'TransferFolderPath'

        If IsNull(@transferFolderPath, '') <> ''
        Begin
            UPDATE T_Jobs
            SET Transfer_Folder_Path = @transferFolderPath
            WHERE Job = @job
        End

        ---------------------------------------------------
        -- If a data package is defined, update entries for
        -- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in T_Job_Parameters
        ---------------------------------------------------
        --
        If @dataPackageID > 0
        Begin
            Exec update_job_param_org_db_info_using_data_pkg @job, @dataPackageID, @deleteIfInvalid=0, @message=@message output, @callingUser=@callingUser
        End
    End

    If @debugMode > 0 And @dataPackageID > 0
    Begin
        -----------------------------------------------
        -- Call update_job_param_org_db_info_using_data_pkg with debug mode enabled
        ---------------------------------------------------
        Exec update_job_param_org_db_info_using_data_pkg @job, @dataPackageID, @deleteIfInvalid=0, @debugMode=1, @scriptNameForDebug=@scriptName, @message=@message output, @callingUser=@callingUser
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    If @myError <> 0 and @msg <> ''
    Begin
        RAISERROR (@msg, 15, 1)
    End

    If @debugMode <> 0
    Begin
        SELECT * FROM #Jobs
        SELECT * FROM #Job_Steps
        SELECT * FROM #Job_Step_Dependencies
        SELECT * FROM #Job_Parameters

        Declare @jobParams varchar(8000) = Cast(@jobParamXML as varchar(8000))

        If @debugMode > 1
        Begin
            EXEC post_log_entry 'Debug', @jobParams, 'make_local_job_in_broker'
        End
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_local_job_in_broker] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[make_local_job_in_broker] TO [Limited_Table_Write] AS [dbo]
GO
