/****** Object:  StoredProcedure [dbo].[update_analysis_job_state_name_cached] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_analysis_job_state_name_cached]
/****************************************************
**
**  Desc: Updates column AJ_StateNameCached in T_Analysis_Job
**        for 1 or more jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   12/12/2007 mem - Initial version (Ticket #585)
**          09/02/2011 mem - Now calling post_usage_log_entry
**          04/03/2014 mem - Now showing @message when @infoOnly > 0
**          05/27/2014 mem - Now using a temporary table to track the jobs that need to be updated (due to deadlock issues)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobStart int = 0,
    @jobFinish int = 0,
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @JobCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    Set @JobStart = IsNull(@JobStart, 0)
    Set @JobFinish = IsNull(@JobFinish, 0)
    set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    If @JobFinish = 0
        Set @JobFinish = 2147483647

    CREATE TABLE #Tmp_JobsToUpdate (
        Job Int Not Null
    )

    ---------------------------------------------------
    -- Find jobs that need to be updated
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_JobsToUpdate (Job)
    SELECT AJ.AJ_JobID
    FROM T_Analysis_Job AJ INNER JOIN
            V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
    WHERE (AJ.AJ_jobID >= @JobStart) AND
            (AJ.AJ_jobID <= @JobFinish) AND
            IsNull(AJ_StateNameCached, '') <> IsNull(AJDAS.Job_State, '')

    If @infoOnly <> 0
    Begin
        ---------------------------------------------------
        -- Preview the jobs
        ---------------------------------------------------
        --
        SELECT  AJ.AJ_jobID AS Job,
                AJ.AJ_StateNameCached AS State_Name_Cached,
                AJDAS.Job_State AS New_State_Name_Cached
        FROM T_Analysis_Job AJ INNER JOIN
             V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
        WHERE AJ.AJ_jobID IN (Select Job From #Tmp_JobsToUpdate)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @message = 'All jobs have up-to-date cached job state names'
        else
            Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' jobs to update'

        SELECT @message as Message
    End
    Else
    Begin

        If Exists (Select * From #Tmp_JobsToUpdate)
        Begin
            ---------------------------------------------------
            -- Update the jobs
            ---------------------------------------------------
            --
            UPDATE T_Analysis_Job
            SET AJ_StateNameCached = IsNull(AJDAS.Job_State, '')
            FROM T_Analysis_Job AJ INNER JOIN
                V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.AJ_jobID = AJDAS.Job
            WHERE AJ.AJ_jobID IN (Select Job From #Tmp_JobsToUpdate)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @JobCount = @myRowCount

            If @JobCount = 0
                Set @message = ''
            Else
                Set @message = ' Updated the cached job state name for ' + Convert(varchar(12), @JobCount) + ' jobs'
        End

    End


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @JobCount) + ' jobs updated'

    If @infoOnly = 0
        Exec post_usage_log_entry 'update_analysis_job_state_name_cached', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_analysis_job_state_name_cached] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_analysis_job_state_name_cached] TO [Limited_Table_Write] AS [dbo]
GO
