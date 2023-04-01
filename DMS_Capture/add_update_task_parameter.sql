/****** Object:  StoredProcedure [dbo].[add_update_task_parameter] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_task_parameter]
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters for a given job
**      Alternatively, use @DeleteParam=1 to delete the given parameter
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          04/04/2011 mem - Expanded [Value] to varchar(4000) in @Job_Parameters
**          01/19/2012 mem - Now using add_update_task_parameter_xml
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @job int,
    @section varchar(128),            -- Example: JobParameters
    @paramName varchar(128),        -- Example: SourceJob
    @value varchar(1024),            -- value for parameter @ParamName in section @Section
    @deleteParam tinyint = 0,        -- When 0, then adds/updates the given parameter; when 1 then deletes the parameter
    @message varchar(512)='' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @paramsXML xml
    Declare @ExistingParamsFound tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_task_parameter', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Lookup the current parameters stored in T_Task_Parameters for this job
    ---------------------------------------------------
    --
    SELECT @paramsXML = Parameters
    FROM T_Task_Parameters
    WHERE Job = @Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @ExistingParamsFound = 1
    Else
    Begin
        Set @message = 'Warning: job not found in T_Task_Parameters'
        If @infoOnly <> 0
            print @message
        Set @paramsXML = ''
    End

    ---------------------------------------------------
    -- Call add_update_task_parameter_xml to perform the work
    ---------------------------------------------------
    --
    exec add_update_task_parameter_xml @paramsXML output, @Section, @ParamName, @Value, @DeleteParam, @message output, @infoOnly


    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- Update T_Task_Parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------
        --
        If @ExistingParamsFound = 1
        Begin
            UPDATE T_Task_Parameters
            SET Parameters = @paramsXML
            WHERE Job = @Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            INSERT INTO T_Task_Parameters( Job, Parameters )
            SELECT @job, @paramsXML
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        if @myError <> 0
        begin
            set @message = 'Error storing parameters in T_Task_Parameters for job ' + Convert(varchar(12), @Job)
        end
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_task_parameter] TO [DDL_Viewer] AS [dbo]
GO
