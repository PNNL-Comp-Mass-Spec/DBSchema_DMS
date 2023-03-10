/****** Object:  StoredProcedure [dbo].[evaluate_step_dependencies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[evaluate_step_dependencies]
/****************************************************
**
**  Desc:
**      Look at all unevaluated dependentices for steps
**      that are finised (completed or skipped) and evaluate them
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/06/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/06/2009 grk - added condition evaluation logic for Completion_Message_Contains http://prismtrac.pnl.gov/trac/ticket/706.
**          06/01/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter @LoopingUpdateInterval
**          12/21/2009 mem - Added parameter @infoOnly
**          12/20/2011 mem - Changed @message to an optional output parameter
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/30/2018 mem - Rename variables and reformat queries
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @message varchar(512)='' output,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5,        -- Seconds between detailed logging while looping through the dependencies
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    Declare @StartTime datetime
    Declare @StatusMessage varchar(512)

    Declare @RowCountToProcess int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    set @message = ''
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    Set @StartTime = GetDate()
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
    If @LoopingUpdateInterval < 2
        Set @LoopingUpdateInterval = 2

    ---------------------------------------------------
    -- table variable for processing dependenices
    ---------------------------------------------------
    CREATE TABLE #Tmp_DepTable (
        Job INT,
        DependentStep INT,
        TargetStep INT,
        TargetState INT,
        TargetCompletionCode INT,
        Condition_Test varchar(256),
        Test_Value varchar(256),
        Enable_Only tinyint,
        SortOrder INT IDENTITY(1,1) NOT NULL
    )

    CREATE INDEX #IX_Tmp_DepTable_SortOrder ON #Tmp_DepTable (SortOrder)

    ---------------------------------------------------
    -- For steps that are waiting,
    -- get unevaluated dependencies that target steps
    -- that are finished (skipped or completed)
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_DepTable (
        Job,
        DependentStep,
        TargetStep,
        TargetState,
        TargetCompletionCode,
        Condition_Test,
        Test_Value,
        Enable_Only
    )
    SELECT JS.Job,
           JSD.Step AS DependentStep,
           JS.Step AS TargetStep,
           JS.State AS TargetState,
           JS.Completion_Code AS TargetCompletionCode,
           JSD.Condition_Test,
           JSD.Test_Value,
           JSD.Enable_Only
    FROM T_Job_Step_Dependencies JSD
         INNER JOIN T_Job_Steps JS
           ON JSD.Target_Step = JS.Step AND
              JSD.Job = JS.Job
         INNER JOIN T_Job_Steps AS JS_B
           ON JSD.Job = JS_B.Job AND
              JSD.Step = JS_B.Step
    WHERE (JSD.Evaluated = 0) AND
          (JS.State IN (3, 5)) AND
          (JS_B.State = 1)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error getting unevaluated steps'
        goto Done
    End
    --
    -- nothing found, nothing to process
    If @myRowCount = 0
    Begin
        If @infoOnly <> 0
            SELECT 'Did not find any job steps to process' AS Message

        goto Done
    End

    If @MaxJobsToProcess > 0
    Begin
        -- Limit the number of jobs to evaluate
        DELETE FROM #Tmp_DepTable
        WHERE NOT Job IN ( SELECT TOP ( @MaxJobsToProcess ) Job
                           FROM #Tmp_DepTable
                           ORDER BY Job )

    End

    If @infoOnly <> 0
    Begin
        -- Preview the steps to process
        SELECT *
        FROM #Tmp_DepTable
        ORDER BY SortOrder
    End

    ---------------------------------------------------
    -- loop though dependencies and evaluate them
    ---------------------------------------------------
    Declare @SortOrder int = 0
    Declare @job int
    Declare @dependentStep int
    Declare @targetStep int
    Declare @targetState int
    Declare @targetCompletionCode int
    Declare @targetCompletionMessage varchar(256)
    Declare @condition_Test varchar(256)
    Declare @testValue varchar(256)
    Declare @Triggered int
    Declare @actualValue int
    Declare @enableOnly tinyint
    Declare @continue tinyint = 1

    SELECT @RowCountToProcess = COUNT(*)
    FROM #Tmp_DepTable
    --
    Set @RowCountToProcess = IsNull(@RowCountToProcess, 0)

    Declare @RowsProcessed int = 0
    Declare @LastLogTime datetime = GetDate()
    --
    while @continue = 1
    Begin -- <a>
        ---------------------------------------------------
        -- get next step dependency
        ---------------------------------------------------
        --
        set @job = 0
        --
        SELECT TOP 1 @SortOrder = SortOrder,
                     @job = Job,
                     @dependentStep = DependentStep,
                     @targetStep = TargetStep,
                     @targetState = TargetState,
                     @targetCompletionCode = TargetCompletionCode,
                     @condition_Test = Condition_Test,
                     @testValue = Test_Value,
                     @enableOnly = Enable_Only
        FROM #Tmp_DepTable
        WHERE SortOrder > @SortOrder
        ORDER BY SortOrder
          --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error getting next dependency'
            goto Done
        End

        If @job = 0
            set @continue = 0
        Else
        Begin -- <b>
            ---------------------------------------------------
            -- Evaluate dependency condition (if one is defined)
            ---------------------------------------------------
            --
            set @Triggered = 0

            ---------------------------------------------------
            -- Skip if signature of dependent step matches
            -- test value (usually used with value of "0"
            -- which happens when there are no parameters)
            --
            If @condition_Test = 'No_Parameters'
            Begin
                -- get filter signature for dependent step
                --
                set @actualValue = -1
                --
                SELECT @actualValue = Signature
                FROM T_Job_Steps
                WHERE Job = @job AND
                      Step = @dependentStep
                --
                If @actualValue = -1
                Begin
                    set @myError = 99
                    set @message = 'Error getting filter signature'
                    goto Done
                End
                --
                If @actualValue = 0
                    set @Triggered = 1

            End

            ---------------------------------------------------
            -- Skip if state of target step
            -- is skipped
            --
            If @condition_Test = 'Target_Skipped'
            Begin
                -- get shared result setting for target step
                --
                set @actualValue = -1
                --
                SELECT @actualValue = State
                FROM T_Job_Steps
                WHERE Job = @job AND
                      Step = @targetStep
                --
                If @actualValue = -1
                Begin
                    set @myError = 98
                    set @message = 'Error getting state'
                    goto Done
                End
                --
                If @actualValue = 3
                    set @Triggered = 1
            End

            ---------------------------------------------------
            -- Skip if completion message of target step
            -- contains test value
            --
            If @condition_Test = 'Completion_Message_Contains'
            Begin
                -- get completion message for target step
                --
                set @targetCompletionMessage = ''
                --
                SELECT @targetCompletionMessage = Completion_Message
                FROM T_Job_Steps
                WHERE Job = @job AND
                      Step = @targetStep
                --
                If @targetCompletionMessage like '%' + @testValue + '%'
                    set @Triggered = 1
            End

            If @infoOnly <> 0 and IsNull(@condition_Test, '') <> ''
                print 'Dependent Step ' + Convert(varchar(12), @dependentStep) + ', Target Step ' + Convert(varchar(12), @targetStep) + ', Condition Test ' + @condition_Test + '; Triggered = ' + Convert(varchar(12), @Triggered)

            ---------------------------------------------------
            -- Copy output folder from target step
            -- to be input folder for dependent step
            -- unless dependency is "Enable_Only"
            ---------------------------------------------------
            --
            If @enableOnly = 0
            Begin -- <EnableOnly>
                Declare @outputFolderName varchar(128) = ''
                --
                SELECT @outputFolderName = Output_Folder_Name
                FROM T_Job_Steps
                WHERE Job = @job AND Step = @targetStep
                  --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    set @message = 'Error getting input folder name for target'
                    goto Done
                End
                --
                If @infoOnly <> 0
                    Print 'Update Job ' + Convert(varchar(12), @Job) + ', Step ' + Convert(varchar(12), @dependentStep) + ' to have Input_Folder_Name = "' + @outputFolderName + '"'
                Else
                    UPDATE T_Job_Steps
                    SET Input_Folder_Name = @outputFolderName
                    WHERE Job = @job AND
                          Step = @dependentStep
                  --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    set @message = 'Error setting output folder name for dependent step'
                    goto Done
                End
            End -- </EnableOnly>

            ---------------------------------------------------
            -- Update state of dependency
            ---------------------------------------------------
            --
            If @infoOnly <> 0
                Print 'Update Job ' + Convert(varchar(12), @Job) + ', Step ' + Convert(varchar(12), @dependentStep) + ' with target step ' + Convert(varchar(12), @targetStep) + ' to have evaluated=1 and triggered=' + convert(varchar(12), @triggered) + ' in table T_Job_Step_Dependencies'
            Else
                UPDATE T_Job_Step_Dependencies
                SET Evaluated = 1,
                    Triggered = @Triggered
                WHERE Job = @job AND
                      Step = @dependentStep AND
                      Target_Step = @targetStep
              --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                set @message = 'Error updating dependency'
                goto Done
            End

            Set @RowsProcessed = @RowsProcessed + 1
        End -- </b>

        If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
        Begin
            Set @StatusMessage = '... Evaluating step dependencies: ' + Convert(varchar(12), @RowsProcessed) + ' / ' + Convert(varchar(12), @RowCountToProcess)
            exec post_log_entry 'Progress', @StatusMessage, 'evaluate_step_dependencies'
            Set @LastLogTime = GetDate()
        End

    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[evaluate_step_dependencies] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[evaluate_step_dependencies] TO [Limited_Table_Write] AS [dbo]
GO
