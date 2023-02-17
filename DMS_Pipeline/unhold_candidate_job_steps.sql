/****** Object:  StoredProcedure [dbo].[UnholdCandidateJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UnholdCandidateJobSteps
/****************************************************
**
**  Desc:
**      Examines the number of step steps with state 2=Enabled
**      If less than @TargetCandidates then updates job steps with state 7 to have state 2
**      such that we will have @TargetCandidates enabled job steps for the given step tool
**
**  Return values: 0:  success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          04/24/2014 mem - Added parameter @MaxCandidatesPlusJobs
**          05/13/2017 mem - Add step state 9 (Running_Remote)
**
*****************************************************/
(
    @StepTool varchar(64) = 'MASIC_Finnigan',
    @TargetCandidates int = 15,
    @MaxCandidatesPlusJobs int = 30,
    @message varchar(512) = '' output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowcount int = 0

    Declare @CandidateSteps int = 0
    Declare @CandidatesPlusRunning int = 0
    Declare @JobsToRelease int = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @StepTool = IsNull(@StepTool, '')
    Set @TargetCandidates = IsNull(@TargetCandidates, 250)
    Set @message = ''

    -----------------------------------------------------------
    -- Count the number of job steps in state 2 for step tool @StepTool
    -----------------------------------------------------------
    --
    SELECT @CandidateSteps = COUNT(*)
    FROM dbo.T_Job_Steps
    WHERE State IN (2, 9) AND
          Step_Tool = @StepTool

    SELECT @CandidatesPlusRunning = COUNT(*)
    FROM dbo.T_Job_Steps
    WHERE State In (2, 4, 9) AND
          Step_Tool = @StepTool

    -----------------------------------------------------------
    -- Compute the number of jobs that need to be released (un-held)
    -----------------------------------------------------------

    Set @JobsToRelease = @MaxCandidatesPlusJobs - @CandidatesPlusRunning
    If @JobsToRelease > @TargetCandidates
        Set @JobsToRelease = @TargetCandidates


    If @TargetCandidates = 1 And @JobsToRelease > 0 OR
       @TargetCandidates >= 1 And @JobsToRelease >= 1
    Begin
        -----------------------------------------------------------
        -- Un-hold @JobsToRelease jobs
        -----------------------------------------------------------

        UPDATE dbo.T_Job_Steps
        SET State = 2
        FROM T_Job_Steps
             INNER JOIN ( SELECT TOP ( @JobsToRelease ) Job,
                                                        Step_Number
                          FROM dbo.T_Job_Steps
                          WHERE state = 7 AND
                                step_tool = @StepTool
                          ORDER BY Job ) ReleaseQ
               ON T_Job_Steps.Job = ReleaseQ.Job AND
                  T_Job_Steps.Step_Number = ReleaseQ.Step_Number
        WHERE T_Job_Steps.State = 7
        --
        set @myRowCount = @@RowCount

        set @message = 'Enabled ' + CONVERT(varchar(12), @myRowCount) + ' jobs for processing'
    End
    Else
    Begin
        set @message = 'Already have ' + CONVERT(varchar(12), @CandidateSteps) + ' candidate jobs and ' + Convert(varchar(12), @CandidatesPlusRunning - @CandidateSteps) + ' running jobs; nothing to do'
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UnholdCandidateJobSteps] TO [DDL_Viewer] AS [dbo]
GO
