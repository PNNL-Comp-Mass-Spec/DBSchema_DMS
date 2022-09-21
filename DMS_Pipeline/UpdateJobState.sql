/****** Object:  StoredProcedure [dbo].[UpdateJobState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateJobState]
/****************************************************
**
**  Desc: 
**  Based on step state, look for jobs that have been completed, 
**  or have entered the "in progress" state, 
**  and update state of job locally and in DMS accordingly
**  
**  First step: evaluate state of steps for jobs that are in new or busy state, 
**  or in transient state of being resumed or reset, and determine what new
**  broker job state should be, and accumulate list of jobs whose new state is different than their
**  current state.  Only steps for jobs in New or Busy state are considered.
** 
**  Current             Current                     New          
**  Broker              Job                         Broker       
**  Job                 Steps                       Job          
**  State               States                      State        
**  -----               -------                     ---------    
**  New or Busy         One or more steps failed    Failed
** 
**  New or Busy         All steps complete          Complete
** 
**  New,Busy,Resuming   One or more steps busy      Busy
**
**  Failed              All steps complete          Complete, though only if max Job Step completion time is greater than Finish time in T_Jobs
** 
** 
** 
**  Second step: go through list of jobs from first step whose current state must be changed and
**  take action in broker and DMS as noted.
** 
**  New             Action by broker
**  Broker          - Always Set job state in broker to new state
**  Job                - Roll up step completion messages and append to comment in DMS job
**  State
**  ------          ---------------------------------------
** 
**  Failed          Current: Update DMS job state to "Failed"
**
**                         In the future, might implement updating
**                         DMS job state to one of several failure states 
**                         according to job step completion codes (See note 1)
**                                - Failed
**                                - No Intermediate Files Created
**                                - Data Extraction Failed
** 
**  Complete        Update DMS job state to "Complete"
** 
**  Busy            Update DMS job state to "In Progress"
** 
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          05/06/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          11/05/2008 grk - fixed issue with broker job state update
**          12/05/2008 mem - Now setting AJ_AssignedProcessorName to 'Job_Broker'
**          12/09/2008 grk - Cleaned out debug code, and uncommented parts of update for DMS job comment and fasta file name
**          12/11/2008 mem - Improved null handling for comments
**          12/15/2008 mem - Now calling SetArchiveUpdateRequired when a job successfully completes
**          12/17/2008 grk - Calling S_SetArchiveUpdateRequired instead of DMS5.dbo.SetArchiveUpdateRequired
**          12/18/2008 grk - Calling CopyJobToHistory when a job finishes (both success or fail)
**          12/29/2008 mem - Updated logic for when to copy comment information to DMS
**          01/12/2009 grk - Handle "No results above threshold" (http://prismtrac.pnl.gov/trac/ticket/706)
**          02/05/2009 mem - Now populating AJ_ProcessingTimeMinutes in DMS (Ticket #722, http://prismtrac.pnl.gov/trac/ticket/722)
**                         - Updated to use the Start and Finish times of the job steps for the job start and finish times (Ticket #722)
**          02/07/2009 mem - Tweaked logic for updating Start and Finish in T_Jobs
**          02/16/2009 mem - Updated processing time calculation to use the Maximum processing time for each step tool, then take the sum of those values to compute the total job time
**          03/16/2009 mem - Updated to handle jobs with non-zero AJ_propagationMode values in T_Analysis_Job in DMS
**          06/02/2009 mem - Now calling S_DMS_UpdateAnalysisJobProcessingStats instead of directly updating DMS5.dbo.T_Analysis_Job (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - No longer calling S_SetArchiveUpdateRequired since UpdateAnalysisJobProcessingStats does this for us
**                         - Added parameter @MaxJobsToProcess
**                         - Renamed synonym for T_Analysis_Job table to S_DMS_T_Analysis_Job
**                         - Altered method of populating @StartMin and @FinishMax to avoid warning "Null value is eliminated by an aggregate or other Set operation"
**          06/03/2009 mem - Added parameter @LoopingUpdateInterval
**          02/27/2010 mem - Now using V_Job_Processing_Time to determine the job processing times
**          04/13/2010 grk - Automatic bypass of updating DMS for jobs with datasetID = 0
**          10/25/2010 grk - Bypass updating job in DMS if job not in DMS (@jobInDMS)
**          05/11/2011 mem - Now updating job state from Failed to Complete if all job steps are now complete and at least one of the job steps finished later than the Finish time in T_Jobs
**          11/14/2011 mem - Now using >= instead of > when looking for jobs to change from Failed to Complete because all job steps are now complete or skipped
**          12/31/2011 mem - Fixed PostedBy name when calling PostLogEntry
**          01/12/2012 mem - Added parameter @infoOnly
**          09/25/2012 mem - Expanded @orgDBName and Organism_DB_Name to varchar(128)
**          02/21/2013 mem - Now updating the state of failed jobs in DMS back to state 2 if they are now in-progress or finished
**          03/13/2014 mem - Now updating @jobInDMS even if @DatasetID is 0
**          09/16/2014 mem - Now looking for failed jobs that should be changed to state 2 in T_Jobs
**          05/01/2015 mem - Now setting the state to 7 (No Intermediate Files Created) if all of the job's steps were skipped
**          05/04/2015 mem - Fix bug in logic that conditionally sets the job state to 7
**          12/31/2015 mem - Setting job state in DMS to 14 if the job comment contains "No results in DeconTools Isos file"
**          09/15/2016 mem - Update jobs in DMS5 that are in state 1=New, but are actually in progress
**          05/13/2017 mem - Treat step state 9 (Running_Remote) as "In progress"
**          05/26/2017 mem - Add step state 16 (Failed_Remote)
**                         - Only call CopyJobToHistory if the job state is 4 or 5
**          06/15/2017 mem - Expand @comment to varchar(512)
**          10/16/2017 mem - Remove the leading semicolon from @comment
**          01/19/2018 mem - Populate column Runtime_Minutes in T_Jobs
**                         - Use column ProcTimeMinutes_CompletedSteps in V_Job_Processing_Time
**          05/10/2018 mem - Append to the job comment, rather than replacing it (provided the job completed successfully)
**          06/12/2018 mem - Send @maxLength to AppendToText
**          03/12/2021 mem - Expand @comment to varchar(1024)
**    
*****************************************************/
(
    @bypassDMS tinyint = 0,
    @message varchar(512) output,
    @MaxJobsToProcess int = 0,
    @LoopingUpdateInterval int = 5,        -- Seconds between detailed logging while looping through the dependencies
    @infoOnly tinyint = 0
)
As
    Set nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @job int
    Declare @newJobStateInBroker int
    --
    Declare @curJob int = 0
    --
    Declare @resultsFolderName varchar(64)
    Set @resultsFolderName = ''
    --
    Declare @orgDBName varchar(128) = ''
    
    Declare @JobPropagationMode int = 0
    
    Declare @done tinyint
    Declare @JobCountToProcess int
    Declare @JobsProcessed int
    Declare @datasetID int
        
    Declare @StartMin datetime
    Declare @FinishMax datetime
    Declare @ProcessingTimeMinutes real
    Declare @UpdateCode int

    Declare @StartTime datetime
    Declare @LastLogTime datetime
    Declare @StatusMessage varchar(512)    

    ---------------------------------------------------
    -- Validate the inputs    
    ---------------------------------------------------
    
    Set @bypassDMS = IsNull(@bypassDMS, 0)
    Set @message = ''
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    Set @StartTime = GetDate()
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
    If @LoopingUpdateInterval < 2
        Set @LoopingUpdateInterval = 2

    Set @InfoOnly = IsNull(@InfoOnly, 0)
    
    ---------------------------------------------------
    -- FUTURE: may need to look at jobs in the holding
    -- state that have been reset
    ---------------------------------------------------

    ---------------------------------------------------
    -- Table variable to hold state changes
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_ChangedJobs (
        Job int,
        NewState int,
        Results_Folder_Name varchar(128),
        Organism_DB_Name varchar(128),
        Dataset_Name varchar(128),
        Dataset_ID int
    )

    CREATE INDEX #IX_Tmp_ChangedJobs_Job ON #Tmp_ChangedJobs (Job)

    If @infoOnly > 0
    Begin
        CREATE TABLE #Tmp_JobStatePreview (
            Job int,
            OldState int,
            NewState int
        )
        
        CREATE INDEX #IX_Tmp_JobStatePreview_Job ON #Tmp_JobStatePreview (Job)
        
    End
    
    ---------------------------------------------------
    -- Determine what current state of active jobs should be
    -- and get list of the ones that need be changed
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_ChangedJobs( Job,
                                  NewState,
                                  Results_Folder_Name,
                                  Organism_DB_Name,
                                  Dataset_Name,
                                  Dataset_ID )
    SELECT Job,
           NewState,
           Results_Folder_Name,
           Organism_DB_Name,
           Dataset,
           Dataset_ID
    FROM (
        -- Look at the state of steps for active or failed jobs
        -- and determine what the new state of each job should be
        SELECT 
          J.Job,
          J.State,
          J.Results_Folder_Name,
          J.Organism_DB_Name,
          CASE 
            WHEN JS_Stats.Failed > 0 THEN 5                                        -- Job Failed
            WHEN JS_Stats.FinishedOrSkipped = Total THEN 
                CASE WHEN JS_Stats.FinishedOrSkipped = JS_Stats.Skipped THEN 7     -- No Intermediate Files Created (all steps skipped)
                Else 4                                                             -- Job Complete
                End            
            WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2                      -- Job In Progress
            Else J.State
          End AS NewState,
          J.Dataset,
          J.Dataset_ID
        FROM   
          (
            -- Count the number of steps for each job 
            -- that are in the busy, finished, or failed states
            SELECT   
                JS.Job,
                COUNT(*) AS Total,
                SUM(CASE 
                    WHEN JS.State IN (3,4,5,9) THEN 1
                    ELSE 0
                    END) AS StartedFinishedOrSkipped,
                SUM(CASE 
                    WHEN JS.State IN (6,16) THEN 1
                    ELSE 0
                    END) AS Failed,
                SUM(CASE 
                    WHEN JS.State IN (3,5) THEN 1
                    ELSE 0
                    END) AS FinishedOrSkipped,
                SUM(CASE
                    WHEN JS.State = 3 Then 1
                    ELSE 0
                    END) AS Skipped
            FROM T_Job_Steps JS
                 INNER JOIN T_Jobs J
                   ON JS.Job = J.Job
            WHERE (J.State IN (1,2,5,20))    -- Job state (not step state!): new, in progress, failed, or resuming state
            GROUP BY JS.Job, J.State
           ) AS JS_Stats 
           INNER JOIN T_Jobs AS J
             ON JS_Stats.Job = J.Job
    ) UpdateQ
    WHERE UpdateQ.State <> UpdateQ.NewState
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Set @JobCountToProcess = @myRowCount
    
    ---------------------------------------------------
    -- Loop through jobs whose state has changed 
    -- and update local state and DMS state
    ---------------------------------------------------
    --
    Set @done = 0
    Set @JobsProcessed = 0
    Set @LastLogTime = GetDate()
    --
    While @done = 0
    Begin -- <a1>
        Set @job = 0
        --
        SELECT TOP 1 
            @job = Job,
            @curJob = Job,
            @newJobStateInBroker = NewState,
            @resultsFolderName = Results_Folder_Name,
            @orgDBName = Organism_DB_Name,
            @datasetID = Dataset_ID
        FROM   
            #Tmp_ChangedJobs
        WHERE
            Job > @curJob
        ORDER BY Job
         --
        SELECT @myError = @@error, @myRowCount = @@rowcount
            
        If @job = 0
            Set @done = 1
        Else
        Begin -- <b1>

            ---------------------------------------------------
            -- Examine the steps for this job to determine actual start/End times
            ---------------------------------------------------

            Set @StartMin = Null
            Set @FinishMax = Null
            Set @ProcessingTimeMinutes = 0

            -- Note: You can use the following query to update @StartMin and @FinishMax
            -- However, when a job has some completed steps and some not yet started, this query 
            --  will trigger the warning "Null value is eliminated by an aggregate or other Set operation"
            -- The warning can be safely ignored, but tends to bloat up the Sql Server Agent logs, 
            --  so we are instead populating @StartMin and @FinishMax separately
            /*
            SELECT @StartMin = Min(Start), 
                   @FinishMax = Max(Finish)
            FROM T_Job_Steps
            WHERE (Job = @job)
             --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            */

            -- Update @StartMin
            -- Note that if no steps have started yet, then @StartMin will be Null
            SELECT @StartMin = Min(Start)       
            FROM T_Job_Steps
            WHERE (Job = @job) AND Not Start Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            -- Update @FinishMax
            -- Note that if no steps have finished yet, then @FinishMax will be Null
            SELECT @FinishMax = Max(Finish)
            FROM T_Job_Steps
            WHERE (Job = @job) AND Not Finish Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            ---------------------------------------------------
            -- Roll up step completion comments
            ---------------------------------------------------
            --
            Declare @comment varchar(1024) = ''
            --
            SELECT @comment = @comment + CASE 
                                            WHEN LTrim(RTrim(Completion_Message)) = '' 
                                            THEN '' 
                                            Else '; ' + Completion_Message 
                                        End
            FROM T_Job_Steps
            WHERE Job = @job AND Not Completion_Message Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @comment Like '; %'
            Begin
                Set @comment = Substring(@comment, 3, Len(@comment))
            End
            
            ---------------------------------------------------
            -- Examine the steps for this job to determine total processing time
            -- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
            --  therefore, we use a Max(ProcessingTime) on steps with the same Step Tool name
            ---------------------------------------------------
    
            SELECT @ProcessingTimeMinutes = ProcTimeMinutes_CompletedSteps
            FROM V_Job_Processing_Time
            WHERE Job = @job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @ProcessingTimeMinutes = IsNull(@ProcessingTimeMinutes, 0)
            
            If @infoOnly > 0
            Begin
                INSERT INTO #Tmp_JobStatePreview (Job, OldState, NewState)
                SELECT Job, State, @newJobStateInBroker
                FROM T_Jobs
                WHERE Job = @job
            End
            Else
            Begin
                
                ---------------------------------------------------
                -- Update local job state, timestamp (if appropriate), and comment
                ---------------------------------------------------
                --                
                UPDATE T_Jobs
                Set 
                    State = @newJobStateInBroker,
                    Start = 
                        CASE WHEN @newJobStateInBroker >= 2                      -- Job state is 2 or higher
                        THEN IsNull(@StartMin, GetDate()) 
                        ELSE Start
                        END,
                    Finish = 
                        CASE WHEN @newJobStateInBroker IN (4, 5, 7)              -- 4=Complete, 5=Failed, 7=No Intermediate Files Created
                        THEN @FinishMax
                        ELSE Finish
                        END,
                    Comment = 
                        CASE WHEN @newJobStateInBroker IN (5) THEN @Comment     -- 5=Failed                        
                        WHEN @newJobStateInBroker IN (4, 7)                     -- 4=Complete, 7=No Intermediate Files Created
                        THEN dbo.AppendToText(Comment, @Comment, 0, '; ', 1024)
                        ELSE Comment
                        END,
                    Runtime_Minutes = @ProcessingTimeMinutes
                WHERE Job = @job
                 --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                
            End

            ---------------------------------------------------
            -- Figure out what DMS job state should be
            -- and update it
            ---------------------------------------------------
            --
            Declare @NewDMSJobState int
            Set @NewDMSJobState = 0 
            --
            Set @NewDMSJobState = CASE @newJobStateInBroker
                                        WHEN 2 THEN 2
                                        WHEN 4 THEN 4
                                        WHEN 5 THEN 5
                                        WHEN 7 THEN 7
                                        Else 99
                                    End                                

            ---------------------------------------------------
            -- If this job has a data extraction step with message "No results above threshold",
            -- change the job state to 14=No Export
            ---------------------------------------------------
            --
            If @NewDMSJobState = 4        -- Complete
            Begin
                If Exists ( SELECT Step_Number
                            FROM T_Job_Steps
                            WHERE Job = @job AND
                                  Completion_Message LIKE '%No results above threshold%' AND
                                  Step_Tool = 'DataExtractor' )
                    Set @NewDMSJobState = 14
            End

            ---------------------------------------------------
            -- If this job has a DeconTools step with message "No results in DeconTools Isos file",
            -- change the job state to 14=No Export
            ---------------------------------------------------
            --
            If @NewDMSJobState = 4        -- Complete
            Begin
                If Exists ( SELECT Step_Number
                            FROM T_Job_Steps
                            WHERE Job = @job AND
                                  Completion_Message LIKE '%No results in DeconTools Isos file%' AND
                                  Step_Tool LIKE 'Decon%' )
                    Set @NewDMSJobState = 14
            End    
                                    
            ---------------------------------------------------
            -- Decide on the fasta file name to save in job
            -- In addition, check whether the job has a Propagation mode of 1
            ---------------------------------------------------
            Declare @jobInDMS INT = 0
            --
            If @datasetID <> 0
            Begin 
                SELECT @orgDBName = CASE
                                        WHEN AJ_proteinCollectionList = 'na' 
                                        THEN AJ_organismDBName
                                        Else @orgDBName
                                    End,
                        @JobPropagationMode = AJ_propagationMode
                FROM S_DMS_T_Analysis_Job
                WHERE AJ_JobID = @job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                SET @jobInDMS = @myRowCount
            End 
            Else
            Begin
                SELECT @JobPropagationMode = AJ_propagationMode
                FROM S_DMS_T_Analysis_Job
                WHERE AJ_JobID = @job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                SET @jobInDMS = @myRowCount
            End

            ---------------------------------------------------
            -- If the DMS job state is 4=complete, but @JobPropagationMode is non-zero,
            -- then change the DMS job state to 14=No Export
            ---------------------------------------------------
            --
            If @NewDMSJobState = 4 AND IsNull(@JobPropagationMode, 0) <> 0
                Set @NewDMSJobState = 14

            ---------------------------------------------------
            -- are we enabled for making changes to DMS?
            ---------------------------------------------------
            --
            If @bypassDMS = 0 AND @jobInDMS > 0 And @infoOnly = 0
            Begin --<c1>
                -- DMS changes enabled, update DMS job state

                -- Uncomment to debug
                -- Declare @DebugMsg varchar(512) = 'Calling S_DMS_UpdateAnalysisJobProcessingStats for job ' + Convert(varchar(12), @Job)
                -- exec PostLogEntry 'Debug', @DebugMsg, 'UpdateJobState'
                
                -- Compute the value for @UpdateCode, which is used as a safety feature to prevent unauthorized job updates
                -- Procedure UpdateAnalysisJobProcessingStats (called by S_DMS_UpdateAnalysisJobProcessingStats) will re-compute @UpdateCode based on @Job
                --  and if the values don't match, the update is not performed
                
                Declare @jobCommentAddnl varchar(512)
                If Len(@comment) <= 512
                    Set @jobCommentAddnl = @comment
                Else
                    Set @jobCommentAddnl = Substring(@comment, 1, 512)

                If @Job % 2 = 0
                    Set @UpdateCode = (@Job % 220) + 14
                Else
                    Set @UpdateCode = (@Job % 125) + 11

                Exec @myError = S_DMS_UpdateAnalysisJobProcessingStats 
                        @Job = @job,
                        @NewDMSJobState = @NewDMSJobState,
                        @NewBrokerJobState = @newJobStateInBroker,
                        @JobStart = @StartMin,
                        @JobFinish = @FinishMax,
                        @ResultsFolderName = @resultsFolderName,
                        @AssignedProcessor = 'Job_Broker',
                        @JobCommentAddnl = @jobCommentAddnl,
                        @OrganismDBName = @orgDBName,
                        @ProcessingTimeMinutes = @ProcessingTimeMinutes,
                        @UpdateCode = @UpdateCode,
                        @infoOnly = 0,
                        @message = @message output
                
                If @myError <> 0
                    Exec PostLogEntry 'Error', @message, 'UpdateJobState'
                    
            End --</c1>

            If @infoOnly = 0
            Begin
                If @newJobStateInBroker IN (4,5)
                Begin
                    ---------------------------------------------------
                    -- Save job history
                    ---------------------------------------------------
                    --
                    exec @myError = CopyJobToHistory @job, @newJobStateInBroker, @message output
                End
                
            End 

            Set @JobsProcessed = @JobsProcessed + 1
        End -- </b1>
        
        If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
        Begin
            Set @StatusMessage = '... Updating job state: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToProcess)
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateJobState'
            Set @LastLogTime = GetDate()
        End
        
        If @MaxJobsToProcess > 0 And @JobsProcessed >= @MaxJobsToProcess
            Set @done = 1
            
    End -- </a1>

    
    If @infoOnly > 0
    Begin
        ---------------------------------------------------
        -- Preview changes that would be made via the above while loop
        ---------------------------------------------------
        --
        SELECT *
        FROM #Tmp_JobStatePreview
        ORDER BY Job
    End
    
    ---------------------------------------------------
    -- Look for jobs in DMS that are failed, yet are not failed in T_Jobs
    -- Also look for jobs listed as new that are actually in progress
    ---------------------------------------------------
    --    
    If @bypassDMS = 0
    Begin -- <a2>
        Declare @JobsToReset AS Table (
            Job int not null, 
            NewState int not null)

        -- Look for jobs that are listed as Failed in DMS, but are in-progress here
        --
        INSERT INTO @JobsToReset (Job, NewState )
        SELECT DMSJobs.AJ_JobID AS Job,
               J.State AS NewState
        FROM S_DMS_T_Analysis_Job AS DMSJobs
             INNER JOIN T_Jobs AS J
               ON J.Job = DMSJobs.AJ_JobiD
        WHERE DMSJobs.AJ_StateID = 5 AND
              J.State IN (1, 2, 4)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -- Also look for jobs that are in state New in DMS, but are in-progress here
        --
        INSERT INTO @JobsToReset (Job, NewState )
        SELECT DMSJobs.AJ_JobID AS Job,
               J.State AS NewState
        FROM S_DMS_T_Analysis_Job AS DMSJobs
             INNER JOIN T_Jobs AS J
               ON J.Job = DMSJobs.AJ_JobiD
        WHERE DMSJobs.AJ_StateID = 1 AND
              J.State IN (2)
        --
        SELECT @myError = @@error, @myRowCount = @myRowCount

        
        If Exists (Select * From @JobsToReset)
        Begin -- <b2>
            -- We might have a large number of jobs to update
            -- Thus, for safety, we'll create a physical temporary table with an index
            -- then populate that table using @JobsToReset
            CREATE TABLE #Tmp_JobsToReset ( 
                Job int not null,
                NewState int not null
            )
            
            CREATE CLUSTERED INDEX #IX_Tmp_JobsToReset ON #Tmp_JobsToReset (Job)

            INSERT INTO #Tmp_JobsToReset (Job, NewState )
            SELECT Job, Max(NewState)
            FROM @JobsToReset
            GROUP BY Job
            
            Set @done = 0
            While @done = 0
            Begin -- <c2>
                Set @job = 0
                --
                SELECT TOP 1 
                    @job = Job,
                    @curJob = Job,
                    @newJobStateInBroker = NewState            
                FROM   
                    #Tmp_JobsToReset
                WHERE
                    Job > @curJob
                ORDER BY Job
                
                If @job = 0
                    Set @done = 1
                Else
                Begin -- <d2>
                    -- Compute the value for @UpdateCode, which is used as a safety feature to prevent unauthorized job updates
                    -- Procedure UpdateAnalysisJobProcessingStats (called by S_DMS_UpdateAnalysisJobProcessingStats) will re-compute @UpdateCode based on @Job
                    --  and if the values don't match, then the update is not performed
                    
                    If @Job % 2 = 0
                        Set @UpdateCode = (@Job % 220) + 14
                    Else
                        Set @UpdateCode = (@Job % 125) + 11

                    -- Update the job start time based on the job steps
                    -- Note that if no steps have started yet, then @StartMin will be Null
                    Set @StartMin = null
                    
                    SELECT @StartMin = Min(Start)       
                    FROM T_Job_Steps
                    WHERE (Job = @job) AND Not Start Is Null
                    
                    Exec @myError = S_DMS_UpdateFailedJobNowInProgress 
                            @Job = @job,
                            @NewBrokerJobState = @newJobStateInBroker,
                            @JobStart = @StartMin,
                            @UpdateCode = @UpdateCode,
                            @infoOnly = @infoOnly,
                            @message = @message output
                    
                    If @myError <> 0
                        Exec PostLogEntry 'Error', @message, 'UpdateJobState'
                            
                End    -- </d2>
            End -- </c2>
            
        End -- </b2>
    End -- </a2>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobState] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobState] TO [Limited_Table_Write] AS [dbo]
GO
