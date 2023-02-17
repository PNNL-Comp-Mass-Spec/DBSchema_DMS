/****** Object:  StoredProcedure [dbo].[create_parameters_for_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_parameters_for_job]
/****************************************************
**
**  Desc:   Get parameters for given job into XML format, populating @paramsXML
**
**      In addition, makes entries in temporary table #Job_Parameters
**
**      CREATE TABLE #Job_Parameters (
**          [Job] int NOT NULL,
**          [Parameters] xml NULL
**      )
**
**
**  Note:   The job parameters come from the DMS5 database (via get_job_param_table),
**          and not from the T_Job_Parameters table local to this DB
**
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          01/31/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameter @DebugMode
**          06/01/2009 mem - Switched from S_get_job_param_table (which pointed to a stored procedure in DMS5)
**                           to get_job_param_table, which is local to this database (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          01/05/2010 mem - Added parameter @SettingsFileOverride
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @paramsXML xml output,
    @message varchar(512) output,
    @SettingsFileOverride varchar(256) = '',    -- When defined, then will use this settings file name instead of the one obtained with V_DMS_PipelineJobParameters (in get_job_param_table)
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
    execute get_job_param_table @job, @SettingsFileOverride, @DebugMode=@DebugMode
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting job parameters'
        goto Done
    end

    if @DebugMode <> 0
        select '@Job_Parameters' AS [Table], * from @Job_Parameters

    ---------------------------------------------------
    -- save job parameters as XML into temp table
    ---------------------------------------------------
    --
    INSERT INTO #Job_Parameters
    (Job, Parameters)
    SELECT @job,
           ( SELECT [Step_Number],
                    [Section],
                    [Name],
                    [Value]
             FROM @Job_Parameters Param
             FOR XML AUTO )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error copying job param scratch to temp'
        goto Done
    end

    ---------------------------------------------------
    -- return XML
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
GRANT VIEW DEFINITION ON [dbo].[create_parameters_for_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_parameters_for_job] TO [Limited_Table_Write] AS [dbo]
GO
