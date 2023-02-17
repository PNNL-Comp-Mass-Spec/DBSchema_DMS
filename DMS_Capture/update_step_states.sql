/****** Object:  StoredProcedure [dbo].[UpdateStepStates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateStepStates]
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based
**      upon completion of target steps that they depend upon
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/01/2020 mem - Tabs to spaces
**
*****************************************************/
(
    @message varchar(512) output,
    @infoOnly tinyint = 0,
    @MaxJobsToProcess int = 0,
    @LoopingUpdateInterval int = 5        -- Seconds between detailed logging while looping through the dependencies
)
As
    set nocount on

    Declare @myError INT = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    Declare @result int

    ---------------------------------------------------
    -- perform state evaluation process followed by
    -- step update process and repeat until no more
    -- step states were changed
    ---------------------------------------------------
    --
    Declare @numStepsSkipped int
    --
    Declare @done TINYINT = 0
    --
    While @done = 0
    Begin

        -- Get unevaluated dependencies for steps that are finished
        -- (skipped or completed)
        --
        exec @result = EvaluateStepDependencies @message output, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

        -- Examine all dependencies for steps in "Waiting" state
        -- and set state of steps that have them all satisfied
        --
        exec @result = UpdateDependentSteps @message output, @numStepsSkipped output, @infoOnly=@infoOnly, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

        -- Repeat if any step states were changed (but only if @infoOnly = 0)
        --
        If not (@numStepsSkipped > 0 AND @infoOnly = 0)
            set @done = 1

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateStepStates] TO [DDL_Viewer] AS [dbo]
GO
