/****** Object:  StoredProcedure [dbo].[GetJobStepParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobStepParamValue]
/****************************************************
**
**  Desc:
**      Get a single job step parameter value
**
**  Note: Data comes from table T_Job_Parameters in the DMS_Pipeline DB, not from DMS5
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          03/09/2021 mem - Initial release
**    
*****************************************************/
(
    @jobNumber int,
    @stepNumber int,
    @section varchar(128) = '',          -- Optional section name to filter on, for example: JobParameters
    @paramName varchar(128) = '',        -- Parameter name to find, for example: SourceJob
    @message varchar(512) = '' output,
    @firstParameterValue varchar(1024) = '' output,        -- The value of the first parameter matched in the retrieved job parameters
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @firstParameterValue = ''
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @section = IsNull(@section, '')
    Set @paramName = IsNull(@paramName, '')
    
    If @paramName= ''
    Begin
        Set @message = '@paramName cannot be empty'
        Set @myError = 12000
        Goto Done
    End

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
    -- Call GetJobStepParamsWork to populate the temporary table
    ---------------------------------------------------
        
    exec @myError = GetJobStepParamsWork @jobNumber, @stepNumber, @message output, @DebugMode
    if @myError <> 0
        Goto Done

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------
        
    If @section <> ''
    Begin
        DELETE FROM #Tmp_JobParamsTable
        WHERE Not [Section] Like @section
    End

    If @paramName <> ''
    Begin
        DELETE FROM #Tmp_JobParamsTable
        WHERE Not [Name] Like @paramName
    End
    
    ---------------------------------------------------
    -- Find the value for the first parameter (sorting on section name then parameter name)
    ---------------------------------------------------
    
    SELECT TOP 1 @firstParameterValue = [Value]
    FROM #Tmp_JobParamsTable
    ORDER BY [Section], [Name]
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    return @myError

GO
