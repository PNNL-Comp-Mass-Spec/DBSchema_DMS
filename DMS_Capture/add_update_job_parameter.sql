/****** Object:  StoredProcedure [dbo].[AddUpdateJobParameter] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddUpdateJobParameter
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
**          01/19/2012 mem - Now using AddUpdateJobParameterXML
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @Job int,
    @Section varchar(128),            -- Example: JobParameters
    @ParamName varchar(128),        -- Example: SourceJob
    @Value varchar(1024),            -- value for parameter @ParamName in section @Section
    @DeleteParam tinyint = 0,        -- When 0, then adds/updates the given parameter; when 1 then deletes the parameter
    @message varchar(512)='' output,
    @infoOnly tinyint = 0
)
As
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @pXML xml
    Declare @ExistingParamsFound tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateJobParameter', @raiseError = 1;
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
    -- Lookup the current parameters stored in T_Job_Parameters for this job
    ---------------------------------------------------
    --
    SELECT @pXML = Parameters
    FROM T_Job_Parameters
    WHERE Job = @Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @ExistingParamsFound = 1
    Else
    Begin
        Set @message = 'Warning: job not found in T_Job_Parameters'
        If @infoOnly <> 0
            print @message
        Set @pXML = ''
    End

    ---------------------------------------------------
    -- Call AddUpdateJobParameterXML to perform the work
    ---------------------------------------------------
    --
    exec AddUpdateJobParameterXML @pXML output, @Section, @ParamName, @Value, @DeleteParam, @message output, @infoOnly


    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- Update T_Job_Parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------
        --
        If @ExistingParamsFound = 1
        Begin
            UPDATE T_Job_Parameters
            SET Parameters = @pXML
            WHERE Job = @Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            INSERT INTO T_Job_Parameters( Job, Parameters )
            SELECT @job, @pXML
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        if @myError <> 0
        begin
            set @message = 'Error storing parameters in T_Job_Parameters for job ' + Convert(varchar(12), @Job)
        end
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateJobParameter] TO [DDL_Viewer] AS [dbo]
GO
