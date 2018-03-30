/****** Object:  StoredProcedure [dbo].[AutoFixFailedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AutoFixFailedJobs]
/****************************************************
**
**  Desc: 
**      Automatically deal with certain types of failed job situations
**
**  Return values: 0:  success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   05/01/2015 mem - Initial version
**          05/08/2015 mem - Added support for "Cannot run BuildSA since less than"
**          05/26/2017 mem - Add step state 16 (Failed_Remote)
**          03/30/2018 mem - Reset MSGF+ steps with "Timeout expired"
**
*****************************************************/
(
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
As
    set nocount on
    
    Declare @myError int
    Declare @myRowcount int
    Set @myRowcount = 0
    Set @myError = 0

    CREATE TABLE #Tmp_JobsToFix (
        Job int not null,
        Step int not null
    )
    
    CREATE CLUSTERED INDEX #Ix_Tmp_JobsToFix_Job ON #Tmp_JobsToFix (Job, Step)
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Look for Bruker_DA_Export jobs that failed with error "No spectra were exported"
    ---------------------------------------------------
    --
    TRUNCATE TABLE #Tmp_JobsToFix
    
    INSERT INTO #Tmp_JobsToFix (Job, Step)
    SELECT Job, Step_Number
    FROM T_Job_Steps
    WHERE Step_Tool = 'Bruker_DA_Export' AND
          State IN (6, 16) AND
          Completion_Message = 'No spectra were exported'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @myRowCount > 0
    Begin -- <a1>

        If @InfoOnly <> 0
        Begin
            SELECT JS.*
            FROM V_Job_Steps JS
                 INNER JOIN #Tmp_JobsToFix F
                   ON JS.Job = F.Job AND
                      JS.Step = F.Step
            ORDER BY Job

        End
        Else
        Begin
            -- We will leave these jobs as "failed" in T_Analysis_Job since there are no results to track
            
            -- Change the step state to 3 (Skipped) for all of the steps in this job
            --
            UPDATE T_Job_Steps
            SET State = 3
            FROM T_Job_Steps Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.Job = F.Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
        End
    End -- </a1>
         
    ---------------------------------------------------
    -- Look for NOMSI jobs that failed with error "No peaks found"
    ---------------------------------------------------
    --
    TRUNCATE TABLE #Tmp_JobsToFix
    
    INSERT INTO #Tmp_JobsToFix( Job, Step )
    SELECT Job,
           Step_Number
    FROM T_Job_Steps
    WHERE Step_Tool = 'NOMSI' AND
          State IN (6, 16) AND
          Completion_Message = 'No peaks found'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin -- <a2>

        If @InfoOnly <> 0
        Begin
            SELECT JS.*
            FROM V_Job_Steps JS
                 INNER JOIN #Tmp_JobsToFix F
                   ON JS.Job = F.Job AND
                      JS.Step = F.Step
            ORDER BY Job

        End
        Else
        Begin
            -- Change the Propagation Mode to 1 (so that the job will be set to state 14 (No Export)
            --
            UPDATE S_DMS_T_Analysis_Job
            SET AJ_PropagationMode = 1,
                AJ_StateID = 2
            FROM S_DMS_T_Analysis_Job Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.AJ_JobID = F.Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            -- Change the job state back to "In Progress"
            --
            UPDATE T_Jobs
            SET State = 2
            FROM T_Jobs Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.Job = F.Job
                   
            -- Change the step state to 3 (Skipped)
            --
            UPDATE T_Job_Steps
            SET State = 3
            FROM T_Job_Steps Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.Job = F.Job AND
                      Target.Step_Number = F.Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End
    End -- </a2>

    ---------------------------------------------------
    -- Look for MSGFPlus jobs where Completion_Message is similar to
    -- "; Cannot run BuildSA since less than 12000 MB of free memory"
     -- or
     -- Error retrieving protein collection or legacy FASTA file: Timeout expired
    ---------------------------------------------------
    --
    TRUNCATE TABLE #Tmp_JobsToFix
    
    INSERT INTO #Tmp_JobsToFix (Job, Step)
    SELECT Job, Step_Number
    FROM T_Job_Steps
    WHERE Step_Tool = 'MSGFPlus' AND
          State IN (6, 16) AND
          (Completion_Message LIKE '%Cannot run BuildSA since less than % MB of free memory%' OR
           Completion_Message LIKE '%Timeout expired%')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin -- <a3>

        If @InfoOnly <> 0
        Begin
            SELECT JS.*
            FROM V_Job_Steps JS
                 INNER JOIN #Tmp_JobsToFix F
                   ON JS.Job = F.Job AND
                      JS.Step = F.Step
            ORDER BY Job

        End
        Else
        Begin

            -- Clear the completion_message and update the step state
            --
            UPDATE T_Job_Steps
            SET State = 2,
                Completion_Message = '',
                Tool_Version_ID = 1,        -- 1=Unknown
                Next_Try = GetDate(),
                Retry_Count = 0,
                Remote_Info_ID = 1,         -- 1=Unknown
                Remote_Timestamp = NULL,
                Remote_Start = NULL,
                Remote_Finish = NULL,
                Remote_Progress = NULL
            FROM T_Job_Steps Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.Job = F.Job AND
                      Target.Step_Number = F.Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            -- Update the job to state 2 and remove the error message
            UPDATE S_DMS_T_Analysis_Job
            SET AJ_StateID = 2,
                AJ_Comment = CASE
                                 WHEN AJ_Comment LIKE 'Auto predefined%' AND
                                      CharIndex(';', AJ_comment) > 0 THEN Substring(AJ_comment, 1, CharIndex(';', AJ_comment) - 1)
                                 WHEN AJ_Comment LIKE 'Auto predefined%' THEN AJ_Comment
                                 ELSE ''
                             END
            FROM S_DMS_T_Analysis_Job Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.AJ_JobID = F.Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            -- Change the job state back to "In Progress"
            --
            UPDATE T_Jobs
            SET State = 2
            FROM T_Jobs Target
                 INNER JOIN #Tmp_JobsToFix F
                   ON Target.Job = F.Job

        End
    End -- </a3>

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AutoFixFailedJobs] TO [DDL_Viewer] AS [dbo]
GO
