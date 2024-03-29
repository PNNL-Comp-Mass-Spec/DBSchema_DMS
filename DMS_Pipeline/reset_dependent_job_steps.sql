/****** Object:  StoredProcedure [dbo].[reset_dependent_job_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_dependent_job_steps]
/****************************************************
**
**  Desc:   Resets entries in T_Job_Steps and T_Job_Step_Dependencies for the given jobs
**          for which the job steps that are complete yet depend on a job step that is enabled,
**          in progress, or completed after the given job step finished
**
**  Auth:   mem
**          05/19/2011 mem - Initial version
**          05/23/2011 mem - Now checking for target steps having state 0 or 1 in addition to 2 or 4
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          05/13/2017 mem - Treat state 9 (Running_Remote) as "In progress"
**          03/22/2021 mem - Do not reset steps in state 7 (Holding)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @jobs varchar(Max),                                 -- List of jobs whose steps should be reset
    @infoOnly tinyint = 0,                              -- 1 to preview the changes
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @JobResetTran varchar(24) = 'DependentJobStepReset'

    BEGIN TRY

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------
        --
        Set @Jobs = IsNull(@Jobs, '')
        Set @InfoOnly = IsNull(@InfoOnly, 0)
        Set @message = ''

        If @Jobs = ''
        Begin
            set @message = 'Job number not supplied'
            print @message
            RAISERROR (@message, 11, 17)
        End

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------
        --

        CREATE TABLE #Tmp_Jobs (
            Job int
        )

        CREATE TABLE #Tmp_JobStepsToReset (
            Job int,
            Step int
        )

        -----------------------------------------------------------
        -- Parse the job list
        -----------------------------------------------------------

        INSERT INTO #Tmp_Jobs (Job)
        SELECT Value
        FROM dbo.parse_delimited_integer_list(@Jobs, ',')
        ORDER BY Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -----------------------------------------------------------
        -- Find steps for the given jobs that need to be reset
        -----------------------------------------------------------
        --
        INSERT INTO #Tmp_JobStepsToReset( Job, Step )
        SELECT DISTINCT JS.Job,
                        JS.Step
        FROM T_Job_Steps JS
             INNER JOIN T_Job_Step_Dependencies
               ON JS.Job = T_Job_Step_Dependencies.Job AND
                  JS.Step = T_Job_Step_Dependencies.Step
             INNER JOIN T_Job_Steps JS_Target
               ON T_Job_Step_Dependencies.Job = JS_Target.Job
                  AND
                  T_Job_Step_Dependencies.Target_Step = JS_Target.Step
        WHERE JS.State >= 2 AND
              JS.State Not In (3, 7) AND
              JS.Job IN ( SELECT Job
                          FROM #Tmp_Jobs ) AND
              (JS_Target.State IN (0, 1, 2, 4, 9) OR
               JS_Target.Start > JS.Finish)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @InfoOnly <> 0
            SELECT JS.*
            FROM V_Job_Steps2 JS
                 INNER JOIN #Tmp_JobStepsToReset JR
                   ON JS.Job = JR.Job AND
                      JS.Step = JR.Step
            ORDER BY JS.Job, JS.Step
        Else
        Begin
            Begin Tran @JobResetTran

            -- Reset evaluated to 0 for the affected steps
            --
            UPDATE T_Job_Step_Dependencies
            SET Evaluated = 0, Triggered = 0
            FROM T_Job_Step_Dependencies JSD
                INNER JOIN #Tmp_JobStepsToReset JR
                ON JSD.Job = JR.Job AND
                    JSD.Step = JR.Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            -- Update the Job Steps to state Waiting
            --
            UPDATE T_Job_Steps
            SET State = 1,                  -- 1=waiting
                Tool_Version_ID = 1,        -- 1=Unknown
                Next_Try = GetDate(),
                Remote_Info_ID = 1          -- 1=Unknown
            FROM T_Job_Steps JS
                 INNER JOIN #Tmp_JobStepsToReset JR
                   ON JS.Job = JR.Job AND
                      JS.Step = JR.Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Commit Tran @JobResetTran
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'reset_dependent_job_steps'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reset_dependent_job_steps] TO [DDL_Viewer] AS [dbo]
GO
