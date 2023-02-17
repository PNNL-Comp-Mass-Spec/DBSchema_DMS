/****** Object:  StoredProcedure [dbo].[RetryMyEMSLUpload] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RetryMyEMSLUpload]
/****************************************************
**
**  Desc:   Resets the DatasetArchive and ArchiveUpdate steps in T_Job_Steps for the 
**          specified jobs, but only if the ArchiveVerify step is failed
**
**          Useful for jobs with Completion message error submitting ingest job
**
**  Auth:   mem
**  Date:   11/17/2014 mem - Initial version
**          02/23/2016 mem - Add Set XACT_ABORT on
**          01/26/2017 mem - Expand @message to varchar(4000)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/09/2017 mem - Clear Completion_Code, Completion_Message, Evaluation_Code, & Evaluation_Message when resetting a job step
**          02/06/2018 mem - Exclude logging some try/catch errors
**			02/02/2023 bcg - Changed from V_Job_Steps to V_Task_Steps
**    
*****************************************************/
(
    @Jobs varchar(Max),                                    -- List of jobs whose steps should be reset
    @InfoOnly tinyint = 0,                                -- 1 to preview the changes
    @message varchar(4000) = '' output
)
As

    Set XACT_ABORT, nocount on
    
    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @JobResetTran varchar(24) = 'ResetArchiveOperation'
    
    Declare @logErrors tinyint = 0

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
        
        CREATE TABLE #Tmp_JobsToSkip (
            Job int
        )

        CREATE TABLE #Tmp_JobsToReset (
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
        FROM dbo.udfParseDelimitedIntegerList(@Jobs, ',')
        ORDER BY Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -----------------------------------------------------------
        -- Look for jobs that have a failed ArchiveVerify step
        -----------------------------------------------------------
        --        
        INSERT INTO #Tmp_JobsToReset( Job )
        SELECT TS.Job
        FROM V_Task_Steps TS
             INNER JOIN #Tmp_Jobs JL
               ON TS.job = JL.Job
        WHERE tool = 'ArchiveVerify' AND
              state = 6
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -----------------------------------------------------------
        -- Look for jobs that do not have a failed ArchiveVerify step
        -----------------------------------------------------------
        --
        INSERT INTO #Tmp_JobsToSkip( Job )
        SELECT JL.Job
        FROM #Tmp_Jobs JL
             LEFT OUTER JOIN #Tmp_JobsToReset JR
               ON JL.Job = JR.Job
        WHERE JR.Job IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Not Exists (Select * From #Tmp_JobsToReset)
        Begin
            Set @message = 'None of the job(s) has a failed ArchiveVerify step'
            print @message
            RAISERROR (@message, 11, 17)
            Goto Done
        End
        
        Declare @SkipCount int = 0

        SELECT @SkipCount = COUNT(*)
        FROM #Tmp_JobsToSkip
        
        If IsNull(@SkipCount, 0) > 0
        Begin
            Set @message = 'Skipping ' + Cast(@SkipCount as varchar(6)) + ' job(s) that do not have a failed ArchiveVerify step'
            Print @message
            Select @message as Warning
        End
                        
        -- Construct a comma-separated list of jobs
        --
        Declare @JobList varchar(max) = null
        
        SELECT @JobList = Coalesce(@JobList + ',' + Cast(Job as varchar(9)), Cast(Job as varchar(9)))
        FROM #Tmp_JobsToReset
        ORDER BY Job

        -----------------------------------------------------------
        -- Reset the ArchiveUpdate or DatasetArchive step
        -----------------------------------------------------------
        --
        
        If @InfoOnly <> 0
        Begin
            SELECT TS.job,
                   TS.step,
                   TS.tool,
                   'Step would be reset' AS Message,
                   TS.state,
                   TS.start,
                   TS.finish
            FROM V_Task_Steps TS
                 INNER JOIN #Tmp_JobsToReset JR
                   ON TS.job = JR.Job
            WHERE tool IN ('ArchiveUpdate', 'DatasetArchive')
            
            Declare @execMsg varchar(256) = 'exec ResetDependentJobSteps ' + @JobList
            print @execMsg
            
        End
        Else
        Begin
            Set @logErrors = 1

            Begin Tran @JobResetTran

            -- Reset the archive step
            --
            UPDATE V_Task_Steps
            Set state = 2,
                completion_code = 0, 
                completion_message = Null, 
                evaluation_code = Null, 
                evaluation_message = Null
            FROM V_Task_Steps TS INNER JOIN #Tmp_JobsToReset JR
               ON TS.job = JR.Job
            WHERE tool IN ('ArchiveUpdate', 'DatasetArchive')
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            -- Reset the state of the dependent steps
            --
            exec ResetDependentJobSteps @JobList, @InfoOnly=0

            -- Reset the retry counts for the ArchiveVerify step
            --
            UPDATE V_Task_Steps
            SET retry_count = 75,
                next_try = DateAdd(minute, 10, GetDate())
            FROM V_Task_Steps TS
                 INNER JOIN #Tmp_JobsToReset JR
                   ON TS.job = JR.Job
            WHERE tool = 'ArchiveVerify'
            
            Commit Tran @JobResetTran
                        
        End    
        
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'RetryMyEMSLUpload'
        End
    END CATCH

Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RetryMyEMSLUpload] TO [DDL_Viewer] AS [dbo]
GO
