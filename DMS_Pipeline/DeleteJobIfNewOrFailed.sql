/****** Object:  StoredProcedure [dbo].[DeleteJobIfNewOrFailed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteJobIfNewOrFailed]
/****************************************************
**
**  Desc:
**      Deletes the given job from T_Jobs if the state is New, Failed, or Holding
**      Does not delete the job if it has running job steps (though if the step started over 48 hours ago, ignore that job step)
**      This procedure is called by DeleteAnalysisJob in DMS5
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/21/2017 mem - Initial release
**          05/26/2017 mem - Check for job step state 9 (Running_Remote)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/01/2017 mem - Fix preview bug
**          09/27/2018 mem - Rename @previewMode to @infoonly
**          05/04/2020 mem - Add additional debug messages
**
*****************************************************/
(
    @job int,
    @callingUser varchar(128) = '',
    @message varchar(512)='' output,
    @infoonly tinyint = 0
)
As
    set nocount on
    
    Declare @myError int= 0
    Declare @myRowCount int = 0

    Declare @jobState int = 0
    Declare @skipMessage varchar(64) = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'DeleteJobIfNewOrFailed', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
 
    Set @message = ''
    Set @infoonly = IsNull(@infoonly, 0)
    
    If @infoonly > 0
    Begin
        If Exists (SELECT * FROM T_Jobs    
                   WHERE Job = @job AND
                         State IN (1, 5, 8) AND
                         NOT Job IN ( SELECT JS.Job
                                      FROM T_Job_Steps JS
                                      WHERE JS.Job = @job AND
                                            JS.State IN (4, 9) AND
                                            JS.Start >= DateAdd(hour, -48, GetDate())) )
        BEGIN            
            ---------------------------------------------------
            -- Preview deletion of jobs that are new, failed, or holding (job state 1, 5, or 8)
            ---------------------------------------------------
            --
            SELECT 'DMS_Pipeline job to be deleted' as Action, *
            FROM T_Jobs
            WHERE Job = @job
        End
        Else
        Begin
            If Exists (SELECT * FROM T_Jobs WHERE Job = @job)
            Begin
                SELECT @jobState = State
                FROM T_Jobs 
                WHERE Job = @job

                IF @jobState IN (2,3,9)
                    SET @skipMessage = 'DMS_Pipeline job will not be deleted; job is in progress'
                ELSE IF @jobState IN (2,3,9)
                    SET @skipMessage = 'DMS_Pipeline job will not be deleted; job is in progress'
                ELSE IF @jobState IN (4,7,14)
                    SET @skipMessage = 'DMS_Pipeline job will not be deleted; job completed successfully'
                ELSE
                    SET @skipMessage = 'DMS_Pipeline job will not be deleted; job state is not New, Failed, or Successful'

                SELECT @skipMessage As Action, *
                FROM T_Jobs
                WHERE Job = @job
            End
            Else
            Begin
                SELECT 'Job not found in T_Jobs: ' + Cast(@job as Varchar(9)) As Action
            End
        End
            
    End
    Else
    Begin
        
        ---------------------------------------------------
        -- Delete the jobs that are new, failed, or holding (job state 1, 5, or 8)
        -- Skip any jobs with running job steps that started within the last 2 days
        ---------------------------------------------------
        --
        DELETE FROM T_Jobs
        WHERE Job = @job AND
              State IN (1, 5, 8) AND
              NOT Job IN ( SELECT JS.Job
                           FROM T_Job_Steps JS
                           WHERE JS.Job = @job AND
                                 JS.State IN (4, 9) AND
                                 JS.Start >= DateAdd(hour, -48, GetDate()) )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error deleting DMS_Pipeline job ' + Cast(@job as varchar(9)) + ' from T_Jobs'
            goto Done
        End

        Print 'Deleted analysis job ' + Cast(@job As varchar(12)) + ' from T_Jobs in DMS_Pipeline'
    End
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteJobIfNewOrFailed] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteJobIfNewOrFailed] TO [Limited_Table_Write] AS [dbo]
GO
