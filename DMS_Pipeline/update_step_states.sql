/****** Object:  StoredProcedure [dbo].[update_step_states] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_step_states]
/****************************************************
**
**  Desc:
**    Determine which steps will be enabled or skipped based
**    upon completion of target steps that they depend upon
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          05/06/2008 -- initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter @infoOnly and renamed @numStepsChanged to @numStepsSkipped (http://prismtrac.pnl.gov/trac/ticket/713)
**          06/02/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter @LoopingUpdateInterval
**          12/21/2009 mem - Now passing @infoOnly to evaluate_step_dependencies
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) output,
    @infoOnly tinyint = 0,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5      -- Seconds between detailed logging while looping through the dependencies
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)

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
        exec @result = evaluate_step_dependencies @message output, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval, @infoOnly=@infoOnly

        -- examine all dependencies for steps in "Waiting" state
        -- and set state of steps that have them all satisfied
        --
        exec @result = update_dependent_steps @message output, @numStepsSkipped output, @infoOnly=@infoOnly, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

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
GRANT VIEW DEFINITION ON [dbo].[update_step_states] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_step_states] TO [Limited_Table_Write] AS [dbo]
GO
