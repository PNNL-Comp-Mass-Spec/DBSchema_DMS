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
**          06/01/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter @LoopingUpdateInterval
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
**    
*****************************************************/
(
    @message varchar(512) = '' output,
    @numStepsSkipped int = 0 output,
    @infoOnly tinyint = 0,
    @MaxJobsToProcess int = 0,
    @LoopingUpdateInterval int = 5        -- Seconds between detailed logging while looping through the dependencies
)
As
    set nocount on
    
    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0
    
    Set @message = ''
    Set @numStepsSkipped = 0
    Set @infoOnly = IsNull(@infoOnly, 0)

    Declare @msg varchar(128)
    Declare @StatusMessage varchar(512)    
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    set @message = ''
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    Declare @StartTime datetime = GetDate()
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
    If @LoopingUpdateInterval < 2
        Set @LoopingUpdateInterval = 2
    
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
    INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name)
    SELECT JSD.Job AS Job,
           JSD.Step_Number AS Step,
           JS.Step_Tool AS Tool,
           J.Priority,
           JS.Dependencies AS Total,
           SUM(JSD.Evaluated) AS Evaluated,
           SUM(JSD.Triggered) AS Triggered,
           JS.Shared_Result_Version AS Shared,
           JS.Signature AS Signature,
           JS.Output_Folder_Name
    FROM T_Job_Steps JS
         INNER JOIN T_Job_Step_Dependencies JSD
           ON JSD.Job = JS.Job AND
              JSD.Step_Number = JS.Step_Number
         INNER JOIN T_Jobs J
           ON JS.Job = J.Job
    WHERE JS.State = 1
    GROUP BY JSD.Job, JSD.Step_Number, JS.Dependencies, 
             JS.Shared_Result_Version, JS.Signature, 
             J.Priority, JS.Step_Tool, JS.Output_Folder_Name
    HAVING JS.Dependencies = SUM(JSD.Evaluated)
    -- 
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error getting step dependencies'
        goto Done
    End
    
    Declare @CandidateStepCount int = @myRowCount

    ---------------------------------------------------
    -- Add waiting steps that have no dependencies
    -- to scratch list
    ---------------------------------------------------
    --
    INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name)
    SELECT JS.Job,
           JS.Step_Number AS Step,
           JS.Step_Tool AS Tool,
           J.Priority,
           JS.Dependencies AS Total,            -- This will always be zero in this query
           0 AS Evaluated,
           0 AS Triggered,
           JS.Shared_Result_Version AS Shared,
           JS.Signature AS Signature,
           JS.Output_Folder_Name
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

    Set @CandidateStepCount = @CandidateStepCount + @myRowCount
    
    If @CandidateStepCount = 0
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

    Declare @RowCountToProcess int

    SELECT @RowCountToProcess = COUNT(*)
    FROM #T_Tmp_Steplist
    --
    Set @RowCountToProcess = IsNull(@RowCountToProcess, 0)

    Declare @continue tinyint = 1
    Declare @RowsProcessed int = 0
    Declare @LastLogTime datetime = GetDate()

    Declare @Job int
    Declare @Step int
    Declare @Tool varchar(64)
    Declare @Total int
    Declare @Evaluated int
    Declare @Triggered int
    Declare @Shared int
    Declare @Signature int
    Declare @outputFolderName varchar(128)
    Declare @ProcessingOrder int = -1

    Declare @newState tinyint
    Declare @numCompleted int
    Declare @numPending int

    Declare @Dataset varchar(128)
    Declare @DatasetID int

    Declare @numStepsUpdated int = 0

    While @continue = 1
    Begin -- <a>
        ---------------------------------------------------
        -- get next step in scratch list
        ---------------------------------------------------
        --
        SELECT TOP 1
            @job = Job,
            @Step = Step,
            @Tool = Tool,
            @Total = Total,
            @Evaluated = Evaluated,
            @Triggered = Triggered,
            @Shared = Shared,
            @Signature = Signature,
            @outputFolderName = Output_Folder_Name,
            @ProcessingOrder = ProcessingOrder
        FROM
            #T_Tmp_Steplist
        WHERE ProcessingOrder > @ProcessingOrder
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
            Set @continue = 0
        Else
        Begin -- <b>
            ---------------------------------------------------
            -- Job step obtained, process it
            --
            -- If all dependencies for the step are evaluated, 
            -- the step's state may be changed
            ---------------------------------------------------
            --
            If @Evaluated = @total
            Begin -- <c>
                --
                ---------------------------------------------------
                -- get information from parent job 
                ---------------------------------------------------
                --
                SELECT @Dataset = Dataset,
                       @DatasetID = Dataset_ID
                FROM T_Jobs
                WHERE Job = @job

                ---------------------------------------------------
                -- If any conditional dependencies were triggered, 
                -- new state will be "Skipped"
                -- otherwise, new state will be "Enabled"
                ---------------------------------------------------
                --
                If @Triggered = 0
                    Set @newState = 2 -- "Enabled"
                Else
                    Set @newState = 3 -- "Skipped

                Set @numCompleted = 0
                Set @numPending = 0

                ---------------------------------------------------
                -- If step has shared results, state change may be affected
                ---------------------------------------------------
                If @Shared <> 0
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
                                VALUES(@outputFolderName)
                        End
                    End -- </h>

                    -- Skip this step if another step has already created the shared results
                    -- Otherwise, continue waiting if another step is making the shared results 
                    --  (the other step will either succeed or fail, and then this step's action will be re-evaluated)
                    --
                    If @numCompleted > 0
                        Set @newState = 3       -- "Skipped"
                    Else 
                    Begin
                        If @numPending > 0
                            Set @newState = 1   -- "Waiting"
                    End
                    
                End -- </d>

                If @infoOnly <> 0
                Begin
                    Set @msg = 'Job ' + Convert(varchar(12), @job) + ', step ' + Convert(varchar(12), @Step) + ', @outputFolderName ' + @outputFolderName
                    
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
                    -- update step state and output folder name
                    -- (input folder name is passed through if step is skipped, 
                    --  unless the tool is DTA_Refinery or Mz_Refinery or ProMex, then the folder name is
                    --  NOT passed through if the tool is skipped)
                    ---------------------------------------------------
                    --
                    If @infoOnly <> 0
                        Print 'Update State in T_Job_Steps for job ' + Convert(varchar(12), @Job) + ', step ' + convert(varchar(12), @Step) + ' from 1 to ' + Convert(varchar(12), @newState)
                    Else
                    Begin
                        -- This query updates the state to @newState
                        -- It may also update Output_Folder_Name; here's the logic:
                            -- If the new state is not 3 (skipped), will leave Output_Folder_Name unchanged
                            -- If the new state is 3, change Output_Folder_Name to be Input_Folder_Name, but only if:
                            --  a. the step tool is not DTA_Refinery or Mz_Refinery or ProMex and 
                            --  b. the Input_Folder_Name is not blank (this check is needed when the first step of a job 
                            --     is skipped; that step will always have a blank Input_Folder_Name, and we don't want
                            --     the Output_Folder_Name to get blank'd out)
                        --
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
                              END
                        WHERE Job = @Job AND
                              Step_Number = @Step AND
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
                    
                    -- bump @numStepsSkipped for each step skipped
                    If @newState = 3
                        Set @numStepsSkipped = @numStepsSkipped + 1
                End -- </e>
    
            End -- </c>
        
            Set @RowsProcessed = @RowsProcessed + 1
        End -- </b>
        
        If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
        Begin
            Set @StatusMessage = '... Updating dependent steps: ' + Convert(varchar(12), @RowsProcessed) + ' / ' + Convert(varchar(12), @RowCountToProcess)
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateDependentSteps'
            Set @LastLogTime = GetDate()
        End

        If @MaxJobsToProcess > 0
        Begin
            SELECT @myRowCount = COUNT(DISTINCT Job)
            FROM #T_Tmp_Steplist
            WHERE ProcessingOrder <= @ProcessingOrder
            
            If IsNull(@myRowCount, 0) >= @MaxJobsToProcess
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
    
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [Limited_Table_Write] AS [dbo]
GO
