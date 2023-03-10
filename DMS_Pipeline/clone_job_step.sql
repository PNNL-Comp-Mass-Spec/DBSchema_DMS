/****** Object:  StoredProcedure [dbo].[clone_job_step] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[clone_job_step]
/****************************************************
**
**  Desc:
**    Clone the given job step in the given job
**    in the temporary tables set up by caller
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/28/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/718)
**          02/06/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from #Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**
*****************************************************/
(
    @job int,
    @paramsXML xml,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Get clone parameters
    ---------------------------------------------------

    ---------------------------------------------------
    declare @step_to_clone int
    set @step_to_clone = 0
    --
    select @step_to_clone = Step
    from #Job_Steps
    where
        Special_Instructions = 'Clone' AND
        Job = @job
    --
    if @step_to_clone = 0 goto Done

    ---------------------------------------------------
    declare @num_clones int
    set @num_clones = 0
    --
    SELECT @num_clones = xmlNode.value('@Value', 'varchar(64)')
    FROM   @paramsXML.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="NumberOfClonedSteps"]') = 1
    --
    if @num_clones = 0 goto Done

    ---------------------------------------------------
    declare @clone_step_num_base int
    set @clone_step_num_base = 0
    --
    SELECT @clone_step_num_base = xmlNode.value('@Value', 'varchar(64)')
    FROM   @paramsXML.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="CloneStepRenumberStart"]') = 1
    --
    if @clone_step_num_base = 0 goto Done

    ---------------------------------------------------
    -- Clone given job step in given job in the temp
    -- tables
    ---------------------------------------------------
    --
    declare @count int
    set @count = 0
    --
    declare @clone_Step int
    --
    while @count < @num_clones
    begin

        set @clone_Step = @clone_step_num_base + @count

        ---------------------------------------------------
        -- copy new job steps from clone step
        ---------------------------------------------------
        --
        INSERT INTO #Job_Steps (
            Job,
            Step,
            Tool,
            CPU_Load,
            Memory_Usage_MB,
            Dependencies,
            Shared_Result_Version,
            Filter_Version,
            Signature,
            State,
            Input_Folder_Name,
            Output_Folder_Name
        )
        SELECT
            Job,
            @clone_Step as Step,
            Tool,
            CPU_Load,
            Memory_Usage_MB,
            Dependencies,
            Shared_Result_Version,
            Filter_Version,
            Signature,
            State,
            Input_Folder_Name,
            Output_Folder_Name
        FROM
            #Job_Steps
        WHERE
            Job = @job AND
            Step = @step_to_clone
        --

        ---------------------------------------------------
        -- copy the clone step's dependencies
        ---------------------------------------------------
        --
        INSERT INTO #Job_Step_Dependencies (
            Job,
            Step,
            Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        )
        SELECT
            Job,
            @clone_Step as Step,
            Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        FROM
            #Job_Step_Dependencies
        WHERE
            Job = @job AND
            Step = @step_to_clone


        ---------------------------------------------------
        -- copy the dependencies that target the clone step
        ---------------------------------------------------
        --
        INSERT INTO #Job_Step_Dependencies (
            Job,
            Step,
            Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        )
        SELECT
            Job,
            Step,
            @clone_Step as Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        FROM
            #Job_Step_Dependencies
        WHERE
            Job = @job AND
            Target_Step = @step_to_clone


        set @count = @count + 1
    end

    ---------------------------------------------------
    -- remove original dependencies
    ---------------------------------------------------
    --
    DELETE FROM #Job_Step_Dependencies
    WHERE
        Job = @job AND
        Target_Step = @step_to_clone

    ---------------------------------------------------
    -- remove original dependencies
    ---------------------------------------------------
    --
    DELETE FROM #Job_Step_Dependencies
    WHERE
        Job = @job AND
        Step = @step_to_clone

    ---------------------------------------------------
    -- remove clone step
    ---------------------------------------------------
    --
    DELETE FROM #Job_Steps
    WHERE
        Job = @job AND
        Step = @step_to_clone

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[clone_job_step] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[clone_job_step] TO [Limited_Table_Write] AS [dbo]
GO
