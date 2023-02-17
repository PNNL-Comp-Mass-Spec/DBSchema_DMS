/****** Object:  StoredProcedure [dbo].[get_job_step_params_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_step_params_xml]
/****************************************************
**
**  Desc:
**    Get job step parameters for given job step
**
**  Note: Data comes from table T_Job_Parameters in the DMS_Pipeline DB, not from DMS5
**
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          12/11/2008 grk - initial release
**          01/14/2009 mem - Increased the length of the Value entries extracted from T_Job_Parameters to be 2000 characters (nvarchar(4000)), Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714
**          05/29/2009 mem - Added parameter @DebugMode
**          12/04/2009 mem - Moved the code that defines the job parameters to get_job_step_params_work
**          05/11/2017 mem - Add parameter @jobIsRunningRemote
**          05/13/2017 mem - Only add RunningRemote to #Tmp_JobParamsTable if @jobIsRunningRemote is non-zero
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobNumber int,
    @stepNumber int,
    @parameters varchar(max) output,    -- Output: job step parameters (in XML)
    @message varchar(512) output,
    @jobIsRunningRemote tinyint = 0,    -- request_step_task_xml will set this to 1 if the newly started job step was state 9
    @debugMode tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0
    --

    set @message = ''
    set @parameters = ''

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_JobParamsTable (
        [Section] Varchar(128),
        [Name] Varchar(128),
        [Value] Varchar(max)
    )

    ---------------------------------------------------
    -- Call get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    exec @myError = get_job_step_params_work @jobNumber, @stepNumber, @message output, @DebugMode
    if @myError <> 0
        Goto Done

    If (IsNull(@jobIsRunningRemote, 0) > 0)
    Begin
        INSERT INTO #Tmp_JobParamsTable (Section, Name, Value)
        VALUES ('StepParameters', 'RunningRemote', @jobIsRunningRemote)
    End

    If @DebugMode > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_xml: populate @st table'

    --------------------------------------------------------------
    -- create XML correctly shaped into settings file format
    -- from flat parameter values table (section/item/value)
    --------------------------------------------------------------
    --
    -- need a separate table to hold sections
    -- for outer nested 'for xml' query
    --
    declare @st table (
        [name] varchar(64)
    )
    INSERT INTO @st( [name] )
    SELECT DISTINCT Section
    FROM #Tmp_JobParamsTable


    If @DebugMode > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_xml: populate @x xml variable'

    --------------------------------------------------------------
    -- Run nested query with sections as outer
    -- query and values as inner query to shape XML
    --------------------------------------------------------------
    --
    declare @x xml
    set @x = (
        SELECT
          name,
          (SELECT
            Name  AS [key],
            IsNull(Value, '') AS [value]
           FROM
            #Tmp_JobParamsTable item
           WHERE item.Section = section.name
                 AND Not item.name Is Null
           for xml auto, type
          )
        FROM
          @st section
        for xml auto, type
    )

    --------------------------------------------------------------
    -- add XML version of all parameters to parameter list as its own parameter
    --------------------------------------------------------------
    --
    declare @xp varchar(max)
    set @xp = '<sections>' + convert(varchar(max), @x) + '</sections>'

    If @DebugMode > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_xml: exiting'

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    ---------------------------------------------------
    -- Return parameters in XML
    ---------------------------------------------------
    --
    set @parameters = @xp
    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_params_xml] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_params_xml] TO [Limited_Table_Write] AS [dbo]
GO
