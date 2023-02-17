/****** Object:  StoredProcedure [dbo].[UpdateDependentSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDependentSteps]
/****************************************************
**
**  Desc:
**      Examine all dependencies for steps in "Waiting" state
**      and update the state of steps for which all dependencies
**      have been satisfied
**
**      The updated state can be affected by conditions on
**      conditional dependencies and by whether or not the
**      step tool produces shared results
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Optimized performance by switching to a temp table with an indexed column
**                           that specifies the order to process the job steps (http://prismtrac.pnl.gov/trac/ticket/713)
**          01/30/2009 grk - Modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          03/18/2009 mem - Now checking T_Job_Steps_History for completed shared result steps if no match is found in T_Job_Steps
**          06/01/2009 mem - Added parameter @maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter @loopingUpdateInterval
**          10/30/2009 grk - Modified skip logic to not pass through folder for DTARefinery tool (temporary ugly hack)
**          02/15/2010 mem - added some additional debug statements to be shown when @infoOnly is non-zero
**          07/01/2010 mem - Updated DTARefinery skip logic to name the tool DTA_Refinery
**          05/25/2011 mem - Now using the Priority column from T_Jobs
**          12/20/2011 mem - Now updating T_Job_Steps.Dependencies if the dependency count listed is lower than that defined in T_Job_Step_Dependencies
**          09/17/2014 mem - Updated output_folder_name logic to recognize tool Mz_Refinery
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          12/01/2016 mem - Use Disable_Output_Folder_Name_Override_on_Skip when finding shared result step tools for which we should not override Output_Folder_Name when the step is skipped
**          05/13/2017 mem - Add check for state 9=Running_Remote
**          03/30/2018 mem - Rename variables, move Declare statements, reformat queries
**          03/02/2022 mem - For data package based jobs, skip checks for existing shared results
**          03/10/2022 mem - Clear the completion code and completion message when skipping a job step
**                         - Check for a job step with shared results being repeatedly skipped, then reset, then skipped again
**
*****************************************************/
(
    @message varchar(512) = '' output,
    @numStepsSkipped int = 0 output,
    @infoOnly tinyint = 0,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5        -- Seconds between detailed logging while looping through the dependencies
)
As
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Set @message = ''
    Set @numStepsSkipped = 0
    Set @infoOnly = IsNull(@infoOnly, 0)

    Declare @msg varchar(256)
    Declare @statusMessage varchar(512)
    Declare @stepSkipCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    set @message = ''
    Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 0)

    Declare @startTime datetime = GetDate()
    Set @loopingUpdateInterval = IsNull(@loopingUpdateInterval, 5)
    If @loopingUpdateInterval < 2
        Set @loopingUpdateInterval = 2

    ---------------------------------------------------
    -- Temp table to hold scratch list of step dependencies
    ---------------------------------------------------
    CREATE TABLE #T_Tmp_Steplist (
        Job int,
        Step int,
        Tool varchar(64),
        Priority int,                                -- Holds Job priority
        Total int,
        Evaluated int,
        Triggered int,
        Shared int,
        Signature int,
        EntryID int identity(1,1) NOT NULL,
        Output_Folder_Name varchar(128) NULL,
        Completion_Code int NULL,
        Completion_Message varchar(512) NULL,
        Evaluation_Code int NULL,
        Evaluation_Message varchar(512) NULL,
        ProcessingOrder int NULL                    -- We will populate this column after the #T_Tmp_Steplist table gets populated
    )

    CREATE INDEX [IX_StepList_ProcessingOrder] ON #T_Tmp_Steplist (ProcessingOrder, Job)

    ---------------------------------------------------
    -- Bump up the value for Dependencies in T_Job_Steps if it is too low
    -- This will happen if new rows are manually added to T_Job_Step_Dependencies
    ---------------------------------------------------
    --
    UPDATE T_Job_Steps
    SET Dependencies = CompareQ.Actual_Dependencies
    FROM T_Job_Steps JS
         INNER JOIN ( SELECT Job,
                             Step_Number,
                             COUNT(*) AS Actual_Dependencies
                      FROM T_Job_Step_Dependencies
                      WHERE Job IN ( SELECT Job FROM T_Job_Steps WHERE State = 1 )
                      GROUP BY Job, Step_Number
                    ) CompareQ
           ON JS.Job = CompareQ.Job AND
              JS.Step_Number = CompareQ.Step_Number AND
              JS.Dependencies < CompareQ.Actual_Dependencies
    WHERE JS.State = 1
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating T_Job_Steps.Dependencies'
        goto Done
    End

    ---------------------------------------------------
    -- get summary of dependencies for steps
    -- in "Waiting" state and add to scratch list
    ---------------------------------------------------
    --
    INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name,
                                 Completion_Code, Completion_Message, Evaluation_Code, Evaluation_Message)
    SELECT JSD.Job AS Job,
           JSD.Step_Number AS Step,
           JS.Step_Tool AS Tool,
           J.Priority,
           JS.Dependencies AS Total,
           SUM(JSD.Evaluated) AS Evaluated,
           SUM(JSD.Triggered) AS Triggered,
           JS.Shared_Result_Version AS Shared,
           JS.Signature AS Signature,
           JS.Output_Folder_Name,
           JS.Completion_Code,
           JS.Completion_Message,
           JS.Evaluation_Code,
           JS.Evaluation_Message
    FROM T_Job_Steps JS
         INNER JOIN T_Job_Step_Dependencies JSD
           ON JSD.Job = JS.Job AND
              JSD.Step_Number = JS.Step_Number
         INNER JOIN T_Jobs J
           ON JS.Job = J.Job
    WHERE JS.State = 1
    GROUP BY JSD.Job, JSD.Step_Number, JS.Dependencies,
             JS.Shared_Result_Version, JS.Signature,
             J.Priority, JS.Step_Tool, JS.Output_Folder_Name,
             JS.Completion_Code, JS.Completion_Message,
             JS.Evaluation_Code, JS.Evaluation_Message
    HAVING JS.Dependencies = SUM(JSD.Evaluated)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error getting step dependencies'
        goto Done
    End

    Select * From #T_Tmp_Steplist

    Declare @candidateStepCount int = @myRowCount

    ---------------------------------------------------
    -- Add waiting steps that have no dependencies
    -- to scratch list
    ---------------------------------------------------
    --
    INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name,
                                Completion_Code, Completion_Message, Evaluation_Code, Evaluation_Message)
    SELECT JS.Job,
           JS.Step_Number AS Step,
           JS.Step_Tool AS Tool,
           J.Priority,
           JS.Dependencies AS Total,            -- This will always be zero in this query
           0 AS Evaluated,
           0 AS Triggered,
           JS.Shared_Result_Version AS Shared,
           JS.Signature AS Signature,
           JS.Output_Folder_Name,
           JS.Completion_Code,
           JS.Completion_Message,
           JS.Evaluation_Code,
           JS.Evaluation_Message
    FROM T_Job_Steps JS
         INNER JOIN T_Jobs J
           ON JS.Job = J.Job
    WHERE JS.State = 1 AND
          JS.Dependencies = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error getting steps without dependencies'
        goto Done
    End

    Set @candidateStepCount = @candidateStepCount + @myRowCount

    If @candidateStepCount = 0
        Goto Done                    -- Nothing to do; jump to the end

    ---------------------------------------------------
    -- Populate the ProcessingOrder column in #T_Tmp_Steplist
    -- Sorting by Priority so that shared steps will tend to be enabled for higher priority jobs first
    ---------------------------------------------------
    --
    UPDATE #T_Tmp_Steplist
    SET ProcessingOrder = LookupQ.ProcessingOrder
    FROM #T_Tmp_Steplist TargetQ
        INNER JOIN ( SELECT EntryID,
                            Row_Number() OVER ( ORDER BY Priority, Job ) AS ProcessingOrder
                    FROM #T_Tmp_Steplist ) LookupQ
        ON TargetQ.EntryID = LookupQ.EntryID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @infoOnly <> 0
        SELECT *
        FROM #T_Tmp_Steplist
        ORDER BY ProcessingOrder

    ---------------------------------------------------
    -- Loop through steps in scratch list
    -- check state of their dependencies,
    -- and update their state, as appropriate
    ---------------------------------------------------

    Declare @rowCountToProcess int

    SELECT @rowCountToProcess = COUNT(*)
    FROM #T_Tmp_Steplist
    --
    Set @rowCountToProcess = IsNull(@rowCountToProcess, 0)

    Declare @continue tinyint = 1
    Declare @rowsProcessed int = 0
    Declare @lastLogTime datetime = GetDate()

    Declare @job int
    Declare @step int
    Declare @tool varchar(64)
    Declare @total int
    Declare @evaluated int
    Declare @triggered int
    Declare @shared int
    Declare @signature int
    Declare @outputFolderName varchar(128)
    Declare @completionCode int
    Declare @completionMessage varchar(512)
    Declare @evaluationCode int
    Declare @evaluationMessage varchar(512)

    Declare @processingOrder int = -1

    Declare @newState tinyint
    Declare @newEvaluationMessage varchar(512)
    Declare @numCompleted int
    Declare @numPending int

    Declare @dataset varchar(128)
    Declare @datasetID int

    Declare @numStepsUpdated int = 0

    While @continue = 1
    Begin -- <a>
        ---------------------------------------------------
        -- get next step in scratch list
        ---------------------------------------------------
        --
        SELECT TOP 1
            @job = Job,
            @step = Step,
            @tool = Tool,
            @total = Total,
            @evaluated = Evaluated,
            @triggered = Triggered,
            @shared = Shared,
            @signature = Signature,
            @outputFolderName = Output_Folder_Name,
            @processingOrder = ProcessingOrder,
            @completionCode = Completion_Code,
            @completionMessage = Completion_Message,
            @evaluationCode = Evaluation_Code,
            @evaluationMessage = Evaluation_Message
        FROM
            #T_Tmp_Steplist
        WHERE ProcessingOrder > @processingOrder
        ORDER BY ProcessingOrder
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error getting next step in list'
            goto Done
        End

        ---------------------------------------------------
        -- No more rows were returned; we are done
        ---------------------------------------------------
        If @myRowCount = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin -- <b>
            ---------------------------------------------------
            -- Job step obtained, process it
            --
            -- If all dependencies for the step are evaluated,
            -- the step's state may be changed
            ---------------------------------------------------
            --
            If @evaluated = @total
            Begin -- <c>
                --
                ---------------------------------------------------
                -- get information from parent job
                ---------------------------------------------------
                --
                SELECT @dataset = Dataset,
                       @datasetID = Dataset_ID
                FROM T_Jobs
                WHERE Job = @job

                ---------------------------------------------------
                -- If any conditional dependencies were triggered,
                -- new state will be "Skipped"
                -- otherwise, new state will be "Enabled"
                ---------------------------------------------------
                --
                If @triggered = 0
                    Set @newState = 2 -- "Enabled"
                Else
                    Set @newState = 3 -- "Skipped

                Set @numCompleted = 0
                Set @numPending = 0

                ---------------------------------------------------
                -- If step has shared results, state change may be affected
                -- Data packaged based jobs cannot have shared results (and will have @datasetID = 0)
                ---------------------------------------------------
                If @shared <> 0 And @datasetID > 0
                Begin -- <d>
                    --
                    -- Any standing shared results that match?
                    --
                    SELECT @numCompleted = COUNT(*)
                    FROM T_Shared_Results
                    WHERE Results_Name = @outputFolderName
                    --
                    If @numCompleted = 0
                    Begin -- <h>
                        -- How many current matching shared results steps are in which states?
                        -- A pending step is one that is enabled or running (not failed or holding)
                        --
                        SELECT @numCompleted = ISNULL(SUM(CASE WHEN State = 5 THEN 1 ELSE 0 END), 0),
                               @numPending = ISNULL(SUM(CASE WHEN State IN (2, 4, 9) THEN 1 ELSE 0 END), 0)
                        FROM T_Job_Steps
                        WHERE Output_Folder_Name = @outputFolderName AND
                              NOT Output_Folder_Name IS NULL

                        If @numCompleted = 0
                        Begin
                            -- Also check T_Job_Steps_History for completed, matching shared results steps
                            -- Old, completed jobs are removed from T_Jobs after a set number of days, meaning it's possible
                            --  that the only record of a completed, matching shared results step will be in T_Job_Steps_History
                            SELECT @numCompleted = COUNT(*)
                            FROM T_Job_Steps_History
                            WHERE Output_Folder_Name = @outputFolderName AND
                                  NOT Output_Folder_Name IS NULL AND
                                  State = 5
                        End

                        --
                        -- If there were any completed shared results not already in
                        -- standing shared results table, make entry in shared results
                        --
                        If @numCompleted > 0
                        Begin
                            If @infoOnly <> 0
                                Print 'Insert "' + @outputFolderName + '" into T_Shared_Results'
                            Else
                                INSERT INTO T_Shared_Results( Results_Name )
                                VALUES (@outputFolderName)
                        End
                    End -- </h>

                    -- Skip this step if another step has already created the shared results
                    -- Otherwise, continue waiting if another step is making the shared results
                    --  (the other step will either succeed or fail, and then this step's action will be re-evaluated)
                    --
                    If @numCompleted > 0
                    Begin
                        -- Check for whether this step has been skipped numerous times in the last 12 hours
                        -- If it has, this indicates that the database metadata for this dataset's other jobs indicates that the step can be skipped,
                        -- but a subsequent step is not finding the shared results and they need to be re-generated

                        SELECT @stepSkipCount = Count(*)
                        FROM T_Job_Step_Events
                        WHERE Job = @job AND
                              Step = @step AND
                              Prev_Target_State = 1 AND
                              Target_State = 3 AND
                              Entered >= DateAdd(hour, -12, GetDate())

                        If @stepSkipCount >= 15
                        Begin
                            Set @msg = 'Job ' + Cast(@job As varchar(12)) + ', step ' + Cast(@step As varchar(12)) +
                                       ' has been skipped ' + Cast(@stepSkipCount As varchar(12)) + ' times in the last 12 hours;' +
                                       ' setting the step state to 2 to allow results to be regenerated'

                            If @infoOnly <> 0
                                Print @msg
                            Else
                                Exec PostLogEntry 'Warning', @msg, 'UpdateDependentSteps'

                            Set @newState = 2       -- "Enabled"
                        End
                        Else
                        Begin
                            Set @newState = 3       -- "Skipped"
                        End
                    End
                    Else
                    Begin
                        If @numPending > 0
                        Begin
                            Set @newState = 1   -- "Waiting"
                        End
                    End

                End -- </d>

                If @infoOnly <> 0
                Begin
                    Set @msg = 'Job ' + Convert(varchar(12), @job) + ', step ' + Convert(varchar(12), @step) + ', @outputFolderName ' + @outputFolderName

                    Set @msg = @msg + ', @numCompleted ' + Convert(varchar(12), @numCompleted) + ', @numPending ' + Convert(varchar(12), @numPending) + ', @newState ' + Convert(varchar(12), @newState)
                    Print @msg
                End

                ---------------------------------------------------
                -- If step state needs to be changed, update step
                ---------------------------------------------------
                --
                If @newState <> 1
                Begin -- <e>

                    ---------------------------------------------------
                    -- Update step state and output folder name
                    -- (input folder name is passed through if step is skipped,
                    --  unless the tool is DTA_Refinery or Mz_Refinery or ProMex, then the folder name is
                    --  NOT passed through if the tool is skipped)
                    ---------------------------------------------------
                    --
                    If @infoOnly <> 0
                    Begin
                        Print 'Update State in T_Job_Steps for job ' + Convert(varchar(12), @job) + ', step ' + convert(varchar(12), @step) + ' from 1 to ' + Convert(varchar(12), @newState)
                    End
                    Else
                    Begin
                        -- The update query below sets Completion_Code to 0 and clears Completion_Message
                        -- If the job step currently has a completion code and/or message, store it in the evaluation message

                        -- This could arise if a job step with shared results was skipped  (e.g. step 2),
                        -- then a subsequent job step could not find the shared results (e.g. step 3)
                        -- and the analysis manager updates the shared result step's state to 2 (enabled),
                        -- then step 2 runs, but fails and has its state set back to 1 (waiting),
                        -- then it is skipped again (via update logic defined earlier in this stored procedure),
                        -- then the subsequent step (step 3) runs again, and this time the shared results were able to be found and it thus succeeds.

                        -- In this scenario (which happened with job 2010021), we do not want the completion message to have any text,
                        -- since we don't want that text to end up in the job comment in the primary job table (T_Analysis_Job).

                        Set @newEvaluationMessage = IsNull(@evaluationMessage, '')

                        If @completionCode > 0
                        Begin
                            Set @newEvaluationMessage = dbo.AppendToText(@newEvaluationMessage, 'Original completion code: ' + Cast(@completionCode As varchar(12)), 0, '; ', 512)
                        End

                        If IsNull(@completionMessage, '') <> ''
                        Begin
                            Set @newEvaluationMessage = dbo.AppendToText(@newEvaluationMessage, 'Original completion msg: ' + @completionMessage, 0, '; ', 512)
                        End

                        -- This query updates the state to @newState
                        -- It may also update Output_Folder_Name; here's the logic:
                            -- If the new state is not 3 (skipped), will leave Output_Folder_Name unchanged
                            -- If the new state is 3, change Output_Folder_Name to be Input_Folder_Name, but only if:
                            --  a. the step tool is not DTA_Refinery or Mz_Refinery or ProMex and
                            --  b. the Input_Folder_Name is not blank (this check is needed when the first step of a job
                            --     is skipped; that step will always have a blank Input_Folder_Name, and we don't want
                            --     the Output_Folder_Name to get blank'd out)

                        UPDATE T_Job_Steps
                        SET State = @newState,
                            Output_Folder_Name =
                              CASE WHEN (@newState = 3 AND
                                        ISNULL(Input_Folder_Name, '') <> '' AND
                                        Step_Tool NOT IN ( SELECT [Name]
                                                           FROM T_Step_Tools
                                                           WHERE Shared_Result_Version > 0 AND
                                                                 Disable_Output_Folder_Name_Override_on_Skip > 0 )
                                        ) THEN Input_Folder_Name
                                   ELSE Output_Folder_Name
                              End,
                              Completion_Code = 0,
                              Completion_Message = '',
                              Evaluation_Message = @newEvaluationMessage
                        WHERE Job = @job AND
                              Step_Number = @step AND
                              State = 1       -- Assure that we only update steps in state 1=waiting
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount
                        --
                        If @myError <> 0
                        Begin
                            Set @message = 'Error updating step state'
                            goto Done
                        End
                    End

                    Set @numStepsUpdated = @numStepsUpdated + 1

                    -- Bump @numStepsSkipped for each skipped step
                    If @newState = 3
                    Begin
                        Set @numStepsSkipped = @numStepsSkipped + 1
                    End
                End -- </e>

            End -- </c>

            Set @rowsProcessed = @rowsProcessed + 1
        End -- </b>

        If DateDiff(second, @lastLogTime, GetDate()) >= @loopingUpdateInterval
        Begin
            Set @statusMessage = '... Updating dependent steps: ' + Convert(varchar(12), @rowsProcessed) + ' / ' + Convert(varchar(12), @rowCountToProcess)
            exec PostLogEntry 'Progress', @statusMessage, 'UpdateDependentSteps'
            Set @lastLogTime = GetDate()
        End

        If @maxJobsToProcess > 0
        Begin
            SELECT @myRowCount = COUNT(DISTINCT Job)
            FROM #T_Tmp_Steplist
            WHERE ProcessingOrder <= @processingOrder

            If IsNull(@myRowCount, 0) >= @maxJobsToProcess
                Set @continue = 0
        End

    End -- </a>

    If @infoOnly <> 0
    Begin
        Print 'Steps updated: ' + Convert(varchar(12), @numStepsUpdated)
        Print 'Steps set to state 3 (skipped): ' + Convert(varchar(12), @numStepsSkipped)
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    DROP TABLE #T_Tmp_Steplist

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [Limited_Table_Write] AS [dbo]
GO
