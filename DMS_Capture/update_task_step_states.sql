/****** Object:  StoredProcedure [dbo].[update_step_states] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_step_states]
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based
**      upon completion of target steps that they depend upon
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/01/2020 mem - Tabs to spaces
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) output,
    @infoOnly tinyint = 0,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5        -- Seconds between detailed logging while looping through the dependencies
)
AS
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
        exec @result = evaluate_step_dependencies @message output, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

        -- Examine all dependencies for steps in "Waiting" state
        -- and set state of steps that have them all satisfied
        --
        exec @result = update_dependent_steps @message output, @numStepsSkipped output, @infoOnly=@infoOnly, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

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
GRANT VIEW DEFINITION ON [dbo].[update_step_states] TO [DDL_Viewer] AS [dbo]
GO
