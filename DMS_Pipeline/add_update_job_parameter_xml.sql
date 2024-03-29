/****** Object:  StoredProcedure [dbo].[add_update_job_parameter_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_job_parameter_xml]
/****************************************************
**
**  Desc:   Adds or updates an entry in the XML parameters in @paramsXML
**          Alternatively, use @DeleteParam=1 to delete the given parameter
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   01/19/2012 mem - Initial Version (refactored from add_update_job_parameter)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**                         - Expand @Value to varchar(4000)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramsXML XML output,              -- XML to update (Input/output parameter)
    @Section varchar(128),              -- Example: JobParameters
    @ParamName varchar(128),            -- Example: SourceJob
    @Value varchar(4000),               -- value for parameter @ParamName in section @Section
    @DeleteParam tinyint = 0,           -- When 0, then adds/updates the given parameter; when 1 then deletes the parameter
    @message varchar(512)='' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_job_parameter_xml', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- get job parameters into table format
    ---------------------------------------------------
    --
    Declare @Job_Parameters table (
        [Section] varchar(128),
        [Name] varchar(128),
        [Value] varchar(4000)
    )

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Populate @Job_Parameters with the parameters
    ---------------------------------------------------
    --
        INSERT INTO @Job_Parameters
            ([Section], [Name], Value)
        SELECT
            xmlNode.value('@Section', 'varchar(128)') as [Section],
            xmlNode.value('@Name', 'varchar(128)') as [Name],
            xmlNode.value('@Value', 'varchar(4000)') as [Value]
        FROM
            @paramsXML.nodes('//Param') AS R(xmlNode)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error parsing job parameters'
            goto Done
        end

    If @infoOnly <> 0
    Begin
        SELECT 'Before update' AS Note, *
        FROM @Job_Parameters
        ORDER BY [Section]
    End

    If @DeleteParam = 0
    Begin
        ---------------------------------------------------
        -- Add/update the specified parameter
        -- First try an update
        ---------------------------------------------------
        --
        UPDATE @Job_Parameters
        SET VALUE = @Value
        WHERE [Section] = @Section AND
              [Name] = @ParamName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0
        Begin
            -- Match not found; Insert a new parameter
            INSERT INTO @Job_Parameters([Section], [Name], [Value])
            VALUES (@Section, @ParamName, @Value)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
    End
    Else
    Begin
        ---------------------------------------------------
        -- Delete the specified parameter
        ---------------------------------------------------
        --
        DELETE FROM @Job_Parameters
        WHERE [Section] = @Section AND
              [Name] = @ParamName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    If @infoOnly <> 0
    Begin
        ---------------------------------------------------
        -- Preview the parameters
        ---------------------------------------------------
        --
        SELECT 'After update' AS Note, *
        FROM @Job_Parameters
        ORDER BY [Section]
    End
    Else
    Begin
        SELECT @paramsXML = ( SELECT [Section],
                             [Name],
                   [Value]
                         FROM @Job_Parameters Param
                         ORDER BY [Section]
                         FOR XML AUTO )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_job_parameter_xml] TO [DDL_Viewer] AS [dbo]
GO
