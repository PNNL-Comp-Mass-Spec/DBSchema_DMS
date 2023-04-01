/****** Object:  StoredProcedure [dbo].[create_parameters_for_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_parameters_for_task]
/****************************************************
**
**  Desc:
**      Get parameters for given job into XML format
**      Make entries in temporary table:
**          #Job_Parameters
**      Update #Job
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/05/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/31/2013 mem - Added parameter @scriptName
**                         - Added support for script 'MyEMSLDatasetPush'
**          07/11/2013 mem - Added support for script 'MyEMSLDatasetPushRecursive'
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @job int,
    @datasetID INT,
    @scriptName varchar(64),
    @paramsXML xml output,
    @message varchar(512) output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- get job parameters from main database
    -- Note that the calling procedure must have already created temporary table #Jobs
    ---------------------------------------------------
    --
    declare @Job_Parameters table (
        [Job] int,
        [Step_Number] int,
        [Section] varchar(64),
        [Name] varchar(128),
        [Value] varchar(2000)       -- Warning: if this field is larger than varchar(2000) then the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
    )
    --
    INSERT INTO @Job_Parameters
        (Job, Step_Number, [Section], [Name], Value)
    execute get_task_param_table @job, @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting job parameters'
        goto Done
    end


    If @ScriptName IN ('MyEMSLDatasetPush', 'MyEMSLDatasetPushRecursive')
    Begin
        INSERT INTO @Job_Parameters
        (Job, Step_Number, [Section], [Name], Value)
        Values (@job, Null, 'JobParameters', 'PushDatasetToMyEMSL', 'True')
    End

    If @ScriptName = 'MyEMSLDatasetPushRecursive'
    Begin
        INSERT INTO @Job_Parameters
        (Job, Step_Number, [Section], [Name], Value)
        Values (@job, Null, 'JobParameters', 'PushDatasetRecurse', 'True')
    End

    if @DebugMode <> 0
        select * from @Job_Parameters

    ---------------------------------------------------
    -- save job parameters as XML into temp table
    ---------------------------------------------------
    --
    INSERT INTO #Job_Parameters
    (Job, Parameters)
    Select @job,(select [Step_Number], [Section], [Name], [Value]
    from @Job_Parameters Param
    for xml auto)

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error copying job param scratch to temp'
        goto Done
    end

    ---------------------------------------------------
    -- Populate @paramsXML
    ---------------------------------------------------
    --
    SELECT @paramsXML = Parameters
    FROM #Job_Parameters
    WHERE Job = @job

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_parameters_for_task] TO [DDL_Viewer] AS [dbo]
GO
