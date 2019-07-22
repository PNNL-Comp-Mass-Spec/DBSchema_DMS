/****** Object:  StoredProcedure [dbo].[RetryQuameterForJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RetryQuameterForJobs]
/****************************************************
**
**  Desc:   Resets failed DatasetQuality step in T_Job_Steps for the specified jobs
**
**          Useful for jobs where Quameter encountered an error
**
**          By default, also sets job parameter IgnoreQuameterErrors to 1, meaning
**          if Quameter fails again, the job will be marked as "skipped" instead of "Failed"
**
**  Auth:   mem
**  Date:   07/11/2019 mem - Initial version
**          07/22/2019 mem - When @infoOnly is 0, return a table listing the jobs that were reset
**    
*****************************************************/
(
    @jobs varchar(Max),                                   -- List of jobs whose steps should be reset
    @infoOnly tinyint = 0,                                -- 1 to preview the changes,
    @ignoreQuameterErrors Tinyint = 1,
    @message varchar(4000) = '' output
)
As

    Set XACT_ABORT, nocount on
    
    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @jobResetTran varchar(24) = 'ResetDatasetQuality'
    
    Declare @logErrors tinyint = 0

    BEGIN TRY 
    
        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------
        --
        Set @jobs = IsNull(@jobs, '')
        Set @infoOnly = IsNull(@infoOnly, 0)
        Set @ignoreQuameterErrors = IsNull(@ignoreQuameterErrors, 1)
        Set @message = ''
        
        If @jobs = ''
        Begin
            Set @message = 'Job number not supplied'
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
        FROM dbo.udfParseDelimitedIntegerList(@jobs, ',')
        ORDER BY Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -----------------------------------------------------------
        -- Look for jobs that have a failed DatasetQuality step
        -----------------------------------------------------------
        --        
        INSERT INTO #Tmp_JobStepsToReset( Job, Step )
        SELECT JS.Job, JS.Step
        FROM V_Job_Steps JS
             INNER JOIN #Tmp_Jobs JL
               ON JS.Job = JL.Job
        WHERE Tool = 'DatasetQuality' AND
              State = 6
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If Not Exists (Select * From #Tmp_JobStepsToReset)
        Begin
            Set @message = 'None of the job(s) has a failed DatasetQuality step'
            print @message
            RAISERROR (@message, 11, 17)
            Goto Done
        End
                                
        -- Construct a comma-separated list of jobs
        --
        Declare @jobList varchar(max) = null
        
        SELECT @jobList = Coalesce(@jobList + ',' + Cast(Job as varchar(9)), Cast(Job as varchar(9)))
        FROM #Tmp_JobStepsToReset
        ORDER BY Job

        -----------------------------------------------------------
        -- Reset the DatasetQuality step
        -----------------------------------------------------------
        --
        
        If @ignoreQuameterErrors > 0
        Begin
            Declare @job Int = 0
            Declare @continue Tinyint = 1

            While @continue > 0
            Begin
                SELECT TOP 1 @Job = Job
                FROM #Tmp_JobStepsToReset
                WHERE Job > @job
                ORDER BY Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @continue = 0
                End
                Else
                Begin
                    If @infoOnly <> 0
                        Print 'Exec AddUpdateJobParameter @job, ''StepParameters'', ''IgnoreQuameterErrors'', ''1'', @infoOnly=0'
                    Else
                        Exec AddUpdateJobParameter @job, 'StepParameters', 'IgnoreQuameterErrors', '1', @infoOnly=0
                End
            End                
        End

        If @infoOnly <> 0
        Begin
            SELECT JS.Job,
                   JS.Step,
                   JS.Tool,
                   'Step would be reset' AS Message,
                   JS.State,
                   JS.Start,
                   JS.Finish
            FROM V_Job_Steps JS
                 INNER JOIN #Tmp_JobStepsToReset JR
                   ON JS.Job = JR.Job AND
                      JS.Step = JR.Step
            
            Declare @execMsg varchar(256) = 'exec ResetDependentJobSteps ' + @jobList
            print @execMsg
            
        End
        Else
        Begin
            Set @logErrors = 1

            Begin Tran @jobResetTran

            -- Reset the DatasetQuality step
            --
            UPDATE V_Job_Steps
            SET State = 2,
                Completion_Code = 0,
                Completion_Message = NULL,
                Evaluation_Code = NULL,
                Evaluation_Message = NULL
            FROM V_Job_Steps JS
                 INNER JOIN #Tmp_JobStepsToReset JR
                   ON JS.Job = JR.Job AND
                      JS.Step = JR.Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            -- Reset the state of the dependent steps
            --
            exec ResetDependentJobSteps @jobList, @infoOnly=0
                        
            Commit Tran @jobResetTran

             SELECT JS.Job,
                    JS.Step,
                    JS.Tool,
                    'Job step has been reset' AS Message,
                    JS.State,
                    JS.Start,
                    JS.Finish
             FROM V_Job_Steps JS
                  INNER JOIN #Tmp_JobStepsToReset JR
                    ON JS.Job = JR.Job AND
                       JS.Step = JR.Step
        End    
        
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'RetryQuameterForJobs'
        End
    END CATCH

Done:

    return @myError

GO
