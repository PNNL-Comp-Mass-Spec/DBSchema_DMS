/****** Object:  StoredProcedure [dbo].[copy_runtime_metadata_from_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_runtime_metadata_from_history]
/****************************************************
**
**  Desc:
**      Copies selected pieces of metadata from the history tables
**      to T_Jobs and T_Job_Steps.  Specifically,
**          Start, Finish, Processor,
**          Completion_Code, Completion_Message,
**          Evaluation_Code, Evaluation_Message,
**          Tool_Version_ID, Remote_Info_ID,
**          Remote_Timestamp, Remote_Start, Remote_Finish
**
**      This procedure is intended to be used after re-running a job step
**      for debugging purposes, but the files created by the job step
**      were only used for comparison purposes back to the original results
**
**      It will only copy the runtime metadata if the Results_Transfer (or Results_Cleanup) steps
**      in T_Job_Steps match exactly the Results_Transfer (or Results_Cleanup) steps in T_Job_Steps_History
**
**  Auth:   mem
**          10/19/2017 mem - Initial release
**          10/31/2017 mem - Look for job states with state 4 or 5 and a null Finish time, but a start time later than a Results_Transfer step
**          02/17/2018 mem - Treat Results_Cleanup steps the same as Results_Transfer steps
**          04/27/2018 mem - Use T_Job_Steps instead of V_Job_Steps so we can see the Start and Finish times for the job step (and not Remote_Start or Remote_Finish)
**          01/04/2021 mem - Add support for PRIDE_Converter jobs
**          11/14/2022 mem - Fix bug referencing the wrong column
**          02/06/2023 bcg - Update after view column rename
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobList varchar(2048),
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @job int
    Declare @jobStep int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @jobList = IsNull(@jobList, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Create two temporary tables
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_Jobs (
        Job int not null,
        UpdateRequired tinyint not null,
        Invalid tinyint not null,
        [Comment] varchar(512) null
    )

    CREATE TABLE #Tmp_JobStepsToUpdate (
        Job int not null,
        Step int not null
    )

    ---------------------------------------------------
    -- Populate a temporary table with jobs to process
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_Jobs (Job, UpdateRequired, Invalid)
    SELECT Value as Job, 0, 0
    FROM dbo.parse_delimited_integer_list(@jobList, ',')

    If Not Exists (SELECT * FROM #Tmp_Jobs)
    Begin
        Set @message = 'No valid jobs were found: ' + @jobList
        Goto Done
    End

    ---------------------------------------------------
    -- Find job steps that need to be updated
    ---------------------------------------------------

    ---------------------------------------------------
    -- First look for jobs with a Finish date after the Start date of the corresponding Results_Transfer step
    --
    INSERT INTO #Tmp_JobStepsToUpdate( Job, Step )
    SELECT JS.Job, JS.Step_Number
    FROM #Tmp_Jobs
         INNER JOIN T_Job_Steps JS
           ON #Tmp_Jobs.Job = JS.Job
         INNER JOIN ( SELECT Job, Step_Number, Start, Input_Folder_Name
                      FROM T_Job_Steps
                      WHERE (Step_Tool In ('Results_Transfer', 'Results_Cleanup'))
                    ) FilterQ
           ON JS.Job = FilterQ.Job AND
              JS.Output_Folder_Name = FilterQ.Input_Folder_Name AND
              JS.Finish > FilterQ.Start AND
              JS.Step_Number < FilterQ.Step_Number
    WHERE Not JS.Step_Tool  In ('Results_Transfer', 'Results_Cleanup')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Next Look for job steps that are state 4 or 5 (Running or Complete) with a null Finish date,
    -- but which started after their corresponding Results_Transfer step
    --
    INSERT INTO #Tmp_JobStepsToUpdate( Job, Step )
    SELECT JS.Job, JS.Step_Number
    FROM #Tmp_Jobs
         INNER JOIN T_Job_Steps JS
           ON #Tmp_Jobs.Job = JS.Job
         INNER JOIN ( SELECT Job, Step_Number, Start, Input_Folder_Name
                      FROM T_Job_Steps
                      WHERE (Step_Tool In ('Results_Transfer', 'Results_Cleanup'))
                    ) FilterQ
           ON JS.Job = FilterQ.Job AND
              JS.Output_Folder_Name = FilterQ.Input_Folder_Name AND
      JS.Finish Is Null AND
              JS.Start > FilterQ.Start AND
              JS.Step_Number < FilterQ.Step_Number
    WHERE Not JS.Step_Tool In ('Results_Transfer', 'Results_Cleanup')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for PRIDE_Converter job steps
    --
    INSERT INTO #Tmp_JobStepsToUpdate( Job, Step )
    SELECT JS.Job, JS.Step_Number
    FROM #Tmp_Jobs
         INNER JOIN T_Job_Steps JS
           ON #Tmp_Jobs.Job = JS.Job
    WHERE JS.Step_Tool = 'PRIDE_Converter'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Update the job list table using #Tmp_JobStepsToUpdate
    --
    UPDATE #Tmp_Jobs
    SET UpdateRequired = 1
    WHERE Job IN ( SELECT DISTINCT Job
                   FROM #Tmp_JobStepsToUpdate )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for jobs with UpdateRequired = 0
    ---------------------------------------------------
    --
    UPDATE #Tmp_Jobs
    SET [Comment] = 'Nothing to update; no job steps were started (or completed) after their corresponding Results_Transfer or Results_Cleanup step'
    WHERE UpdateRequired = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for jobs where the Results_Transfer steps do not match T_Job_Steps_History
    ---------------------------------------------------
    --
    UPDATE #Tmp_Jobs
    SET [Comment] = 'Results_Transfer step in T_Job_Steps has a different Start/Finish value vs. T_Job_Steps_History; ' +
           'Step ' + Cast(InvalidQ.Step AS varchar(9)) + '; ' +
           'Start ' +   Convert(varchar(34), InvalidQ.Start, 120) +  ' vs. ' + Convert(varchar(34), InvalidQ.Start_History, 120) + '; ' +
           'Finish ' +  Convert(varchar(34), InvalidQ.Finish, 120) + ' vs. ' + Convert(varchar(34), InvalidQ.Finish_History, 120),
        Invalid = 1
    FROM #Tmp_Jobs
         INNER JOIN (  SELECT JS.Job,
                             JS.Step_Number AS Step,
                             JS.Start, JS.Finish,
                             JSH.Start AS Start_History,
                             JSH.Finish AS Finish_History
                      FROM T_Job_Steps JS
                           INNER JOIN T_Job_Steps_History JSH
                             ON JS.Job = JSH.Job AND
                                JS.Step_Number = JSH.Step_Number AND
                                JSH.Most_Recent_Entry = 1
                      WHERE JS.Job IN (Select DISTINCT Job FROM #Tmp_JobStepsToUpdate) AND
                            JS.Step_Tool In ('Results_Transfer', 'Results_Cleanup') AND
                            (JSH.Start <> JS.Start OR JSH.Finish <> JS.Finish)
                   ) InvalidQ
           ON #Tmp_Jobs.Job = InvalidQ.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @infoOnly > 0
    Begin
        UPDATE #Tmp_Jobs
        SET [Comment] = 'Metadata would be updated'
        FROM #Tmp_Jobs J
            INNER JOIN #Tmp_JobStepsToUpdate JSU
            ON J.Job = JSU.Job
        WHERE J.Invalid = 0
    End

    If @infoOnly = 0 And Exists (SELECT * FROM  #Tmp_Jobs J INNER JOIN #Tmp_JobStepsToUpdate JSU ON J.Job = JSU.Job WHERE J.Invalid = 0)
    Begin -- <a>

        ---------------------------------------------------
        -- Update metadata for the job steps in #Tmp_JobStepsToUpdate,
        -- filtering out any jobs with Invalid = 1
        ---------------------------------------------------
        --
        UPDATE T_Job_Steps
        SET Start = JSH.Start,
            Finish = JSH.Finish,
            State = JSH.State,
            Processor = JSH.Processor,
            Completion_Code = JSH.Completion_Code,
            Completion_Message = JSH.Completion_Message,
            Evaluation_Code = JSH.Evaluation_Code,
            Evaluation_Message = JSH.Evaluation_Message,
            Tool_Version_ID = JSH.Tool_Version_ID,
            Remote_Info_ID = JSH.Remote_Info_ID
        FROM #Tmp_Jobs J
             INNER JOIN #Tmp_JobStepsToUpdate JSU
               ON J.Job = JSU.Job
             INNER JOIN T_Job_Steps JS
               ON JS.Job = JSU.Job AND
                  JSU.Step = JS.Step_Number
             INNER JOIN T_Job_Steps_History JSH
               ON JS.Job = JSH.Job AND
                  JS.Step_Number = JSH.Step_Number AND
                  JSH.Most_Recent_Entry = 1
        WHERE J.Invalid = 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'No job steps were updated; this indicates a bug.  Examine the temp table contents'

            SELECT '#Tmp_Jobs' AS TheTable, * FROM #Tmp_Jobs

            SELECT '#Tmp_JobStepsToUpdate' AS TheTable, * FROM #Tmp_JobStepsToUpdate
        End

        If @myRowCount = 1
        Begin
            SELECT @job = JSU.Job,
                @jobStep = JSU.Step
            FROM #Tmp_Jobs J
                INNER JOIN #Tmp_JobStepsToUpdate JSU
                ON J.Job = JSU.Job
            WHERE J.Invalid = 0

            Set @message = 'Updated step ' + Cast(@jobStep as varchar(9)) + ' for job ' + CAST (@job as varchar(9)) + ' in T_Job_Steps, copying metadata from T_Job_Steps_History'
        End

        If @myRowCount > 1
        Begin
            Set @message = 'Updated ' + Cast(@myRowCount as varchar(9)) + ' job steps in T_Job_Steps, copying metadata from T_Job_Steps_History'
        End

        UPDATE #Tmp_Jobs
        SET [Comment] = 'Metadata updated'
        FROM #Tmp_Jobs J
            INNER JOIN #Tmp_JobStepsToUpdate JSU
            ON J.Job = JSU.Job
        WHERE J.Invalid = 0

    End -- </a>

    ---------------------------------------------------
    -- Show job steps that were updated, or would be updated, or that cannot be updated
    ---------------------------------------------------
    --
    SELECT J.Job,
           J.UpdateRequired,
           J.Invalid,
           J.[Comment],
           JS.Dataset,
           JS.Step,
           JS.Tool,
           JS.State_Name,
           JS.State,
           JSH.State as New_State,
           JS.Start,
           JS.Finish,
           JSH.Start AS New_Start,
           JSH.Finish AS New_Finish,
           JS.Input_Folder,
           JS.Output_Folder,
           JS.Processor,
           JSH.Processor AS New_Processor,
           JS.Tool_Version_ID,
           JS.Tool_Version,
           JS.Completion_Code,
           JS.Completion_Message,
           JS.Evaluation_Code,
           JS.Evaluation_Message
    FROM #Tmp_JobStepsToUpdate JSU
         INNER JOIN V_Job_Steps JS
           ON JSU.Job = JS.Job AND
              JSU.Step = JS.Step
         INNER JOIN T_Job_Steps_History JSH
           ON JS.Job = JSH.Job AND
              JS.Step = JSH.Step_Number AND
              JSH.Most_Recent_Entry = 1
         RIGHT OUTER JOIN #Tmp_Jobs J
           ON J.Job = JSU.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    If @message <> ''
        SELECT @message as Message

    return @myError

GO
