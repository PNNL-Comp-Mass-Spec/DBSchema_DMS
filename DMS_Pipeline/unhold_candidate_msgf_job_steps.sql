/****** Object:  StoredProcedure [dbo].[unhold_candidate_msgf_job_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[unhold_candidate_msgf_job_steps]
/****************************************************
**
**  Desc:
**      Examines the number of MSGF step steps with state 2
**      If less than @TargetCandidates then updates job steps with state 7 to have state 2
**      such that we will have @TargetCandidates enabled job steps for MSGF
**
**      Only updates jobs where the DataExtractor step has Tool_Version_ID >= 82 and is complete
**
**  Return values: 0:  success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          05/12/2017 mem - Update Tool_Version_ID, Next_Try, and Remote_Info_ID
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @stepTool varchar(64) = 'MSGF',
    @targetCandidates int = 25,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowcount int
    set @myRowcount = 0
    set @myError = 0


    Declare @CandidateSteps int = 0
    Declare @JobsToRelease int = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @StepTool = IsNull(@StepTool, '')
    Set @TargetCandidates = IsNull(@TargetCandidates, 25)
    Set @message = ''

    -----------------------------------------------------------
    -- Count the number of job steps in state 2 for step tool @StepTool
    -----------------------------------------------------------
    --
    SELECT @CandidateSteps = COUNT(*)
    FROM dbo.T_Job_Steps
    WHERE state = 2 AND
          Tool = @StepTool

    -----------------------------------------------------------
    -- Compute the number of jobs that need to be released (un-held)
    -----------------------------------------------------------
    Set @JobsToRelease = @TargetCandidates - @CandidateSteps

    If @TargetCandidates = 1 And @JobsToRelease > 0 OR
       @TargetCandidates > 1 And @JobsToRelease > 1
    Begin
        -----------------------------------------------------------
        -- Un-hold @JobsToRelease jobs
        -----------------------------------------------------------

        UPDATE dbo.T_Job_Steps
        SET State = 2,
            Tool_Version_ID = 1,        -- 1=Unknown
            Next_Try = GetDate(),
            Remote_Info_ID = 1          -- 1=Unknown
        FROM T_Job_Steps
             INNER JOIN ( SELECT TOP ( @JobsToRelease ) JS_MSGF.Job,
                                                        JS_MSGF.Step
                          FROM T_Job_Steps JS_MSGF
                               INNER JOIN T_Job_Steps ExtractQ
                                 ON JS_MSGF.Job = ExtractQ.Job
                                    AND
                                    ExtractQ.Tool = 'DataExtractor'
                          WHERE (JS_MSGF.State = 7) AND
                                (JS_MSGF.Tool = @StepTool) AND
                                (ExtractQ.State = 5) AND
                                (ExtractQ.Tool_Version_ID >= 82)
                          ORDER BY Job DESC ) ReleaseQ
               ON T_Job_Steps.Job = ReleaseQ.Job AND
                  T_Job_Steps.Step = ReleaseQ.Step
        WHERE T_Job_Steps.State = 7
        --
        set @myRowCount = @@RowCount

        set @message = 'Enabled ' + CONVERT(varchar(12), @myRowCount) + ' jobs for processing'
    End
    Else
    Begin
        set @message = 'Already have ' + CONVERT(varchar(12), @CandidateSteps) + ' candidate jobs; nothing to do'
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[unhold_candidate_msgf_job_steps] TO [DDL_Viewer] AS [dbo]
GO
