/****** Object:  StoredProcedure [dbo].[EvaluateStepDependencies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EvaluateStepDependencies] 
/****************************************************
**
**  Desc: 
**      Look at all unevaluated dependencies for steps that are finished (completed or skipped)
**      and evaluate them
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          05/17/2019 mem - Switch from folder to directory
**          06/01/2020 mem - Add support for step state 13 (Inactive)
**
*****************************************************/
(
    @message varchar(512) output,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5        -- Seconds between detailed logging while looping through the dependencies
)
As
    set nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    set @message = ''

    Declare @StartTime datetime
    Declare @LastLogTime datetime
    Declare @StatusMessage varchar(512)    

    Declare @RowCountToProcess int
    Declare @RowsProcessed int
        
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    set @message = ''
    Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 0)

    Set @StartTime = GetDate()
    Set @loopingUpdateInterval = IsNull(@loopingUpdateInterval, 5)
    If @loopingUpdateInterval < 2
        Set @loopingUpdateInterval = 2
        
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
           JSD.Step_Number AS DependentStep,
           JS.Step_Number AS TargetStep,
           JS.State AS TargetState,
           JS.Completion_Code AS TargetCompletionCode,
           JSD.Condition_Test,
           JSD.Test_Value,
           JSD.Enable_Only
    FROM T_Job_Step_Dependencies JSD
         INNER JOIN T_Job_Steps JS
           ON JSD.Target_Step_Number = JS.Step_Number AND
              JSD.Job = JS.Job
         INNER JOIN T_Job_Steps AS JS_B
           ON JSD.Job = JS_B.Job AND
              JSD.Step_Number = JS_B.Step_Number
    WHERE (JSD.Evaluated = 0) AND
          (JS.State IN (3, 5, 13)) AND
          (JS_B.State = 1)
    -- 
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting unevaluated steps'
        goto Done
    end
    --
    -- nothing found, nothing to process
    if @myRowCount = 0
        goto Done

    If @maxJobsToProcess > 0
    Begin
        -- Limit the number of jobs to evaluate
        DELETE FROM #Tmp_DepTable
        WHERE NOT Job IN ( SELECT TOP ( @maxJobsToProcess ) Job
                           FROM #Tmp_DepTable
                           ORDER BY Job )
        
    End
        
    ---------------------------------------------------
    -- loop though dependencies and evaluate them
    ---------------------------------------------------
    Declare @SortOrder int
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
    Declare @done int
    
    SELECT @RowCountToProcess = COUNT(*)
    FROM #Tmp_DepTable
    --
    Set @RowCountToProcess = IsNull(@RowCountToProcess, 0)

    set @done = 0
    Set @RowsProcessed = 0
    Set @LastLogTime = GetDate()
    --
    while @done = 0
    begin --<a>
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
        ORDER BY SortOrder
          -- 
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error getting next dependency'
            goto Done
        end
        
        if @job = 0
            set @done = 1
        else
        begin --<b>
            ---------------------------------------------------
            -- Evaluate dependency condition (if one is defined)
            ---------------------------------------------------
            --
            set @Triggered = 0
/*            
            ---------------------------------------------------
            -- skip if signature of dependent step matches
            -- test value (usually used with value of "0"
            -- which happens when there are no parameters)
            --
            if @condition_Test = 'No_Parameters'
            begin
                -- get filter signature for dependent step
                --
                set @actualValue = -1
                --
                SELECT @actualValue = Signature
                FROM T_Job_Steps
                WHERE Job = @job AND Step_Number = @dependentStep        
                --
                if @actualValue = -1
                begin
                    set @myError = 99
                    set @message = 'Error getting filter signature'
                    goto Done
                end
                --
                if @actualValue = 0
                    set @Triggered = 1
            end
            else
*/
-- skip if instrument class not in list
-- skip if dataset type not in list
            ---------------------------------------------------
            -- skip if state of target step
            -- is skipped
            --
            if @condition_Test = 'Target_Skipped'
            begin
                -- get shared result setting for target step
                --
                set @actualValue = -1
                --
                SELECT 
                    @actualValue = State
                FROM T_Job_Steps
                WHERE Job = @job AND Step_Number = @targetStep        
                --
                if @actualValue = -1
                begin
                    set @myError = 98
                    set @message = 'Error getting state'
                    goto Done
                end
                --
                if @actualValue = 3
                    set @Triggered = 1
            end
            else
            ---------------------------------------------------
            -- skip if completion message of target step
            -- contains test value
            --
            if @condition_Test = 'Completion_Message_Contains'
            begin
                -- get completion message for target step
                --
                set @targetCompletionMessage = ''
                --
                SELECT 
                    @targetCompletionMessage = Completion_Message
                FROM T_Job_Steps
                WHERE Job = @job AND Step_Number = @targetStep        
                --
                if @targetCompletionMessage like '%' + @testValue + '%'
                    set @Triggered = 1
            end

            -- FUTURE: more conditions here

            ---------------------------------------------------
            -- Copy output directory from target step
            -- to be input directory for dependent step
            -- unless dependency is "Enable_Only"
            ---------------------------------------------------
            --
            if @enableOnly = 0
            begin --<eo>
                Declare @outputDirectoryName varchar(128) = ''
                --
                SELECT @outputDirectoryName = Output_Folder_Name
                FROM T_Job_Steps
                WHERE Job = @job AND Step_Number = @targetStep        
                  -- 
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                if @myError <> 0
                begin
                    set @message = 'Error getting input directory name for target'
                    goto Done
                end
                --
                UPDATE T_Job_Steps
                SET Input_Folder_Name = @outputDirectoryName
                WHERE Job = @job AND Step_Number = @dependentStep        
                  -- 
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                if @myError <> 0
                begin
                    set @message = 'Error setting output directory name for dependent step'
                    goto Done
                end
            end --<eo>
            
            ---------------------------------------------------
            -- update state of dependency
            ---------------------------------------------------
            --
            UPDATE T_Job_Step_Dependencies
            SET Evaluated = 1,
                Triggered = @Triggered
            WHERE Job = @job AND
                  Step_Number = @dependentStep AND
                  Target_Step_Number = @targetStep
            -- 
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                set @message = 'Error updating dependency'
                goto Done
            end
            
            ---------------------------------------------------
            -- remove dependency from processing table
            ---------------------------------------------------
            --
            DELETE FROM #Tmp_DepTable
            WHERE SortOrder = @SortOrder 
            
            Set @RowsProcessed = @RowsProcessed + 1
        end --<b>

        If DateDiff(second, @LastLogTime, GetDate()) >= @loopingUpdateInterval
        Begin
            Set @StatusMessage = '... Evaluating step dependencies: ' + Convert(varchar(12), @RowsProcessed) + ' / ' + Convert(varchar(12), @RowCountToProcess)
            exec PostLogEntry 'Progress', @StatusMessage, 'EvaluateStepDependencies'
            Set @LastLogTime = GetDate()
        End

    end --<a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[EvaluateStepDependencies] TO [DDL_Viewer] AS [dbo]
GO
