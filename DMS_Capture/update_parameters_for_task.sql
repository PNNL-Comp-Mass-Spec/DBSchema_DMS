/****** Object:  StoredProcedure [dbo].[update_parameters_for_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_parameters_for_task]
/****************************************************
**
**  Desc:
**      Update parameters for one or more jobs
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   12/16/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - removed path ID fields
**          01/28/2010 grk - modified to use create_parameters_for_task, and to take list of jobs
**          04/13/2010 mem - Fixed bug that didn't properly update T_Task_Parameters when #Job_Parameters contains multiple jobs (because @jobList contained multiple jobs)
**                         - Added support for jobs being present in T_Tasks but not present in T_Task_Parameters
**          05/18/2011 mem - Updated @jobList to varchar(max)
**          09/17/2012 mem - Now updating Storage_Server in T_Tasks if it differs from V_DMS_Capture_Job_Parameters
**          08/27/2013 mem - Now updating 4 fields in T_Tasks if they are null (which will be the case if a job was copied from T_Tasks_History to T_Tasks yet the job had no parameters in T_Task_Parameters_History)
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          06/01/2015 mem - Changed update logic for Capture_Subfolder to pull from DMS5 _unless_ the value in DMS5 is null
**          03/24/2016 mem - Switch to using parse_delimited_integer_list to parse the list of jobs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          01/30/2018 mem - Always update instrument settings using data in DMS (Storage_Server, Instrument, Instrument_Class, Max_Simultaneous_Captures, Capture_Subfolder)
**          05/17/2019 mem - Switch from folder to directory
**          08/31/2022 mem - Rename view V_DMS_Capture_Job_Parameters to V_DMS_Dataset_Metadata
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @jobList varchar(max),
    @message varchar(512) = '' output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_parameters_for_task', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Parse the job list
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Jobs (
        Job int
    )

    INSERT INTO #Tmp_Jobs (Job)
    SELECT Value
    FROM dbo.parse_delimited_integer_list(@jobList, ',')
    ORDER BY Value
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -- Update values in T_Tasks

    UPDATE T_Tasks
    SET Storage_Server = IsNull(VDD.Storage_Server_Name, J.Storage_Server),
        Instrument = IsNull(VDD.Instrument_Name, J.Instrument),
        Instrument_Class = IsNull(VDD.Instrument_Class, J.Instrument_Class),
        Max_Simultaneous_Captures = IsNull(VDD.Max_Simultaneous_Captures, J.Max_Simultaneous_Captures),
        Capture_Subfolder = IsNull(VDD.Capture_Subfolder, J.Capture_Subfolder)
    FROM T_Tasks J
         INNER JOIN V_DMS_Get_Dataset_Definition AS VDD
           ON J.Dataset_ID = VDD.Dataset_ID
         INNER JOIN #Tmp_Jobs
           ON J.Job = #Tmp_Jobs.Job

    ---------------------------------------------------
    -- Create temp table for jobs that are being updated
    -- and populate it
    -- (needed by call to get_task_param_table which create_parameters_for_task calls)
    ---------------------------------------------------
    --
    CREATE TABLE #Jobs (
        [Job] int NOT NULL,
        [Priority] int NULL,
        [Script] varchar(64) NULL,
        [State] int NOT NULL,
        [Dataset] varchar(128) NULL,
        [Dataset_ID] int NULL,
        [Results_Directory_Name] varchar(128) NULL,
        Storage_Server varchar(64) NULL,
        Instrument varchar(24) NULL,
        Instrument_Class VARCHAR(32),
        Max_Simultaneous_Captures int NULL,
        Capture_Subdirectory varchar(255) NULL
    )
    --
    INSERT INTO #Jobs (
        [Job],
        [Priority],
        [Script],
        [State],
        [Dataset],
        [Dataset_ID],
        [Results_Directory_Name],
        Storage_Server,
        Instrument,
        Instrument_Class,
        Max_Simultaneous_Captures,
        Capture_Subdirectory
    )
    SELECT J.Job,
           J.Priority,
           J.Script,
           J.State,
           J.Dataset,
           J.Dataset_ID,
           J.Results_Folder_Name,
           J.Storage_Server,
           J.Instrument,
           J.Instrument_Class,
           J.Max_Simultaneous_Captures,
           J.Capture_Subfolder
    FROM T_Tasks J
         INNER JOIN #Tmp_Jobs
           ON J.Job = #Tmp_Jobs.Job


    ---------------------------------------------------
    -- temp table to accumulate XML parameters for
    -- jobs in list
    -- (parameters for jobs will be added by create_parameters_for_task)
    ---------------------------------------------------
    --
    CREATE TABLE #Job_Parameters (
        [Job] int NOT NULL,
        [Parameters] xml NULL
    )

    IF @DebugMode = 0
    Begin
        -- Update the Storage Server stored in T_Tasks if it differs from V_DMS_Dataset_Metadata
        --
        UPDATE T_Tasks
        SET Storage_Server = DS.Storage_Server_Name
        FROM T_Tasks
                INNER JOIN V_DMS_Dataset_Metadata DS
                ON T_Tasks.Dataset_ID = DS.Dataset_ID
                INNER JOIN #Jobs
                ON #Jobs.Job = T_Tasks.Job
        WHERE IsNull(DS.Storage_Server_Name, '') <> '' AND IsNull(T_Tasks.Storage_Server, '') <> DS.Storage_Server_Name
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    ---------------------------------------------------
    -- loop through jobs and accumulate parameters
    -- into temp table
    ---------------------------------------------------
    --
    declare @job int
    declare @prevJob int
    declare @datasetID int
    declare @scriptName varchar(64)
    declare @done tinyint

    set @done = 0
    set @prevJob = 0
    --
    while @done = 0
    begin --<a>
        --
        set @job = 0
        --
        SELECT TOP 1
            @job = Job,
            @datasetID = Dataset_ID,
            @scriptName = Script
        FROM
            #Jobs
        WHERE Job > @prevJob
        ORDER BY Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to get next unitiated job'
            goto Done
        end

        ---------------------------------------------------
        -- if no job was found, we are done
        -- otherwise, get parameters for job
        ---------------------------------------------------
        if @job = 0
            set @done = 1
        else
        begin --<b>
            -- set up to get next job on next pass
            set @prevJob = @job

            declare @paramsXML XML

            -- get parameters for job (and also store in temp table #Job_Parameters)
            -- Parameters are returned in @paramsXML
            exec @myError = create_parameters_for_task @job, @datasetID, @scriptName, @paramsXML output, @message output, @DebugMode = @DebugMode

        end --<b>
    end --<a>

    ---------------------------------------------------
    -- replace params in T_Task_Parameters (or output debug message)
    ---------------------------------------------------
    --
    IF @DebugMode > 0
    BEGIN
        SELECT
            Job,
            CONVERT(VARCHAR(4096), [Parameters]) AS Params
        FROM
            #Job_Parameters
    END
    ELSE
    BEGIN
        -- Update existing jobs in T_Task_Parameters
        --
        UPDATE T_Task_Parameters
        SET Parameters = Source.Parameters
        FROM T_Task_Parameters Target
             INNER JOIN #Job_Parameters Source
               ON Target.Job = Source.Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -- Add any missing jobs
        --
        INSERT INTO T_Task_Parameters( Job,
                                      Parameters )
        SELECT Source.Job,
               Source.Parameters
        FROM #Job_Parameters Source
             LEFT OUTER JOIN T_Task_Parameters
               ON Source.Job = T_Task_Parameters.Job
        WHERE T_Task_Parameters.Job IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    END

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_parameters_for_task] TO [DDL_Viewer] AS [dbo]
GO
