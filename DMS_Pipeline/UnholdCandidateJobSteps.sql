/****** Object:  StoredProcedure [dbo].[UnholdCandidateJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UnholdCandidateJobSteps
/****************************************************
**
**	Desc: 
**		Examines the number of step steps with state 2=Enabled
**		If less than @TargetCandidates then updates job steps with state 7 to have state 2
**		such that we will have @TargetCandidates enabled job steps for the given step tool
**
**	Return values: 0:  success, otherwise, error code
**
**	Auth:	mem
**	Date:	12/20/2011 mem - Initial version
**    
*****************************************************/
(
	@StepTool varchar(64) = 'DataExtractor',
	@TargetCandidates int = 250,
	@message varchar(512) = '' output
)
As
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
	Set @TargetCandidates = IsNull(@TargetCandidates, 250)
	Set @message = ''

	-----------------------------------------------------------
	-- Count the number of job steps in state 2 for step tool @StepTool
	-----------------------------------------------------------
	--
	SELECT @CandidateSteps = COUNT(*)
	FROM dbo.T_Job_Steps
	WHERE state = 2 AND
	      step_tool = @StepTool

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
		set @message = 'Already have ' + CONVERT(varchar(12), @CandidateSteps) + ' candidate jobs; nothing to do'
	End

	Return @myError

GO
