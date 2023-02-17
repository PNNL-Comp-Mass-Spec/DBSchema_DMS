/****** Object:  StoredProcedure [dbo].[get_job_step_params_as_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_step_params_as_table]
/****************************************************
**
**  Desc:   Get job step parameters for given job step
**
**  Note: Data comes from table T_Job_Parameters in the DMS_Capture DB, not from DMS5
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          05/05/2010 mem - Initial release
**          02/12/2020 mem - Add argument @paramName, which can be used to filter the results
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobNumber int,
    @stepNumber int,
    @paramName varchar(512) = '',           -- Optional parameter name to filter on (supports wildcards)
    @message varchar(512) = '' output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    --
    set @message = ''

    Set @paramName = Ltrim(Rtrim(Coalesce(@ParamName, '')))

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------
    --
    CREATE TABLE #ParamTab (
        [Section] Varchar(128),
        [Name] Varchar(128),
        [Value] Varchar(max)
    )

    ---------------------------------------------------
    -- Call get_job_step_params to populate the temporary table
    ---------------------------------------------------

    exec @myError = get_job_step_params @jobNumber, @stepNumber, @message output, @DebugMode
    if @myError <> 0
        Goto Done

    ---------------------------------------------------
    -- Return the contents of #Tmp_JobParamsTable
    ---------------------------------------------------

    If @ParamName = '' Or @ParamName = '%'
    Begin
        SELECT *
        FROM #ParamTab
        ORDER BY [Section], [Name], [Value]
    End
    Else
    Begin
        SELECT *
        FROM #ParamTab
        Where Name Like @ParamName
        ORDER BY [Section], [Name], [Value]

        Print 'Only showing parameters match ' + @ParamName
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_params_as_table] TO [DDL_Viewer] AS [dbo]
GO
