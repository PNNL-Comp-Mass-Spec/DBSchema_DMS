/****** Object:  StoredProcedure [dbo].[UpdateStepStates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateStepStates
/****************************************************
**
**	Desc: 
**    Determine which steps will be enabled or skipped based
**    upon completion of target steps that they depend upon
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	09/02/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**    
*****************************************************/
(
	@message varchar(512) output,
	@infoOnly tinyint = 0,
	@MaxJobsToProcess int = 0,
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)
	
	declare @result int

	---------------------------------------------------
	-- perform state evaluation process followed by 
	-- step update process and repeat until no more
	-- step states were changed
	---------------------------------------------------
	--
	declare @numStepsSkipped int
	--
	declare @done tinyint
	set @done = 0
	--
	while @done = 0
	begin --<a>

		-- get unevaluated dependencies for steps that are finished 
		-- (skipped or completed)
		--
		exec @result = EvaluateStepDependencies @message output, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

		-- examine all dependencies for steps in "Waiting" state
		-- and set state of steps that have them all satisfied
		--
		exec @result = UpdateDependentSteps @message output, @numStepsSkipped output, @infoOnly=@infoOnly, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval
		
		-- repeat if any step states were changed (but only if @infoOnly = 0)
		--
		if not (@numStepsSkipped > 0 AND @infoOnly = 0)
			set @done = 1
		
	end --<a>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateStepStates] TO [DDL_Viewer] AS [dbo]
GO
