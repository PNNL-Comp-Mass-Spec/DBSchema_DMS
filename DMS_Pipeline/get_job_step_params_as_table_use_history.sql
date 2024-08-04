/****** Object:  StoredProcedure [dbo].[get_job_step_params_as_table_use_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_step_params_as_table_use_history]
/****************************************************
**
**  Desc:
**    Get job step parameters for given job step
**
**  Note: Data comes from table T_Job_Parameters_History in the DMS_Pipeline DB, not from DMS5
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          07/31/2013 mem - Initial release
**          01/05/2018 mem - Add parameters @section, @paramName, and @firstParameterValue
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/03/2024 mem - Rename @jobNumber argument to @job
**                         - Rename @stepnumber argument to @step
**
*****************************************************/
(
    @job int,
    @step int,
    @section varchar(128) = '',         -- Optional section name to filter on, for example: JobParameters
    @paramName varchar(128) = '',       -- Optional parameter name to filter on, for example: SourceJob
    @message varchar(512) = '' output,
    @firstParameterValue varchar(1024) = '' output,     -- The value of the first parameter in the retrieved job parameters; useful when using both @section and @paramName
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
    set @firstParameterValue = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @section = IsNull(@section, '')
    Set @paramName = IsNull(@paramName, '')


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
    -- Call get_job_step_params_from_history_work to populate the temporary table
    ---------------------------------------------------

    exec @myError = get_job_step_params_from_history_work @job, @step, @message output, @DebugMode
    if @myError <> 0
        Goto Done

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------

    If @section <> ''
    Begin
        DELETE FROM #Tmp_JobParamsTable
        WHERE [Section] <> @section
    End

    If @paramName <> ''
    Begin
        DELETE FROM #Tmp_JobParamsTable
        WHERE [Name] <> @paramName
    End

    ---------------------------------------------------
    -- Cache the first parameter value (sorting on section name then parameter name)
    ---------------------------------------------------

    SELECT TOP 1 @firstParameterValue = [Value]
    FROM #Tmp_JobParamsTable
    ORDER BY [Section], [Name]

    ---------------------------------------------------
    -- Return the contents of #Tmp_JobParamsTable
    ---------------------------------------------------

    SELECT *
    FROM #Tmp_JobParamsTable
    ORDER BY [Section], [Name], [Value]
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_params_as_table_use_history] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_job_step_params_as_table_use_history] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_job_step_params_as_table_use_history] TO [svc-dms] AS [dbo]
GO
