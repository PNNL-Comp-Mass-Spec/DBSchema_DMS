/****** Object:  StoredProcedure [dbo].[ExtendMultipleJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ExtendMultipleJobs
/****************************************************
**
**  Desc:   Applies an extension script to a series of jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/22/2010 mem - Initial version
**
*****************************************************/
(
    @JobList varchar(max),                  -- Comma separated list of jobs to extend
    @extensionScriptName varchar(64),       -- Example: Sequest_Extend_MSGF
    @message varchar(512)='' output,
    @infoOnly tinyint = 0,
    @DebugMode tinyint = 0
)
As
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    Declare @ScriptFirst varchar(64)
    Declare @ScriptLast varchar(64)
    Declare @Job int
    Declare @continue tinyint

    CREATE TABLE #Tmp_JobsToExtend (
        Job int NOT NULL,
        Valid tinyint NOT NULL,
        Script varchar(64) NULL
    )

    ---------------------------------------------------
    -- Populate a temporary table with the list of jobs
    ---------------------------------------------------
    --

    INSERT INTO #Tmp_JobsToExtend (Job, Valid)
    SELECT Value, 0
    FROM dbo.udfParseDelimitedIntegerList(@JobList, ',')


    ---------------------------------------------------
    -- Validate that the job numbers exist in T_Jobs or T_Jobs_History
    ---------------------------------------------------
    --
    UPDATE #Tmp_JobsToExtend
    SET Valid = 1, Script = T_Jobs.Script
    FROM #Tmp_JobsToExtend
         INNER JOIN T_Jobs
           ON #Tmp_JobsToExtend.Job = T_Jobs.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    UPDATE #Tmp_JobsToExtend
    SET Valid = 1, Script = T_Jobs_History.Script
    FROM #Tmp_JobsToExtend
         INNER JOIN T_Jobs_History
           ON #Tmp_JobsToExtend.Job = T_Jobs_History.Job
    WHERE T_Jobs_History.State = 4
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Warn the user if any invalid jobs are present
    ---------------------------------------------------
    --
    IF EXISTS (SELECT * FROM #Tmp_JobsToExtend WHERE Valid = 0)
    Begin
        SELECT 'Invalid job (either not in T_Jobs or in T_Jobs_History but does not have state=4)', Job
        FROM #Tmp_JobsToExtend
        WHERE Valid = 0
    End

    DELETE FROM #Tmp_JobsToExtend
    WHERE Valid = 0

    If NOT EXISTS (SELECT * FROM #Tmp_JobsToExtend)
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
           @ScriptLast =  MAX(Script),
           @Job = MIN(Job)
    FROM #Tmp_JobsToExtend
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If IsNull(@ScriptFirst,'') <> IsNull(@ScriptLast, '')
    Begin
        Set @message = 'The jobs must all have the same script defined: ' + @ScriptFirst + ' <> ' + @ScriptLast
        Set @myError = 50001
        Goto Done
    End

    ---------------------------------------------------
    -- Validate that the extension script is appropriate for the existing job script
    ---------------------------------------------------
    --
    Exec @myError = ValidateExtensionScriptForJob @Job, @extensionScriptName, @message = @message output

    If @myError <> 0
        Goto Done


    ---------------------------------------------------
    -- Loop through the jobs and call CreateJobSteps for each
    ---------------------------------------------------
    --
    Set @Job = 0
    Set @continue = 1
    Set @myError = 0

    While @Continue = 1 And @myError = 0
    Begin
        SELECT TOP 1 @Job = Job
        FROM #Tmp_JobsToExtend
        WHERE Job > @Job
        ORDER BY JOb
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        IF @myRowCount = 0
            Set @Continue = 0
        Else
        Begin

            exec @myError = CreateJobSteps @message=@message output,
                                @mode='ExtendExistingJob',
                                @extensionScriptName=@extensionScriptName,
                                @existingJob = @Job,
                                @infoOnly=@infoOnly,
                                @DebugMode=@DebugMode


        End

    End


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ExtendMultipleJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ExtendMultipleJobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ExtendMultipleJobs] TO [PNL\D3M578] AS [dbo]
GO
