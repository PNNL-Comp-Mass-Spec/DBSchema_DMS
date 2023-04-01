/****** Object:  StoredProcedure [dbo].[add_update_task_parameter_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_task_parameter_xml]
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters in @paramsXML
**      Alternatively, use @DeleteParam=1 to delete the given parameter
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/24/2012 mem - Ported from DMS_Pipeline DB
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @paramsXML XML output,                -- XML to update (Input/output parameter)
    @section varchar(128),            -- Example: JobParameters
    @paramName varchar(128),        -- Example: SourceJob
    @value varchar(1024),            -- value for parameter @ParamName in section @Section
    @deleteParam tinyint = 0,        -- When 0, then adds/updates the given parameter; when 1 then deletes the parameter
    @message varchar(512)='' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- get job parameters into table format
    ---------------------------------------------------
    --
    declare @Job_Parameters table (
        [Section] varchar(64),
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
            xmlNode.value('@Section', 'varchar(64)') as [Section],
            xmlNode.value('@Name', 'varchar(64)') as [Name],
            xmlNode.value('@Value', 'varchar(1024)') as [Value]
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
GRANT VIEW DEFINITION ON [dbo].[add_update_task_parameter_xml] TO [DDL_Viewer] AS [dbo]
GO
