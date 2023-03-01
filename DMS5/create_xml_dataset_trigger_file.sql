/****** Object:  StoredProcedure [dbo].[create_xml_dataset_trigger_file] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[create_xml_dataset_trigger_file]
/****************************************************
**  Desc:   Creates an XML dataset trigger file to deposit into a directory
**          where the DIM will pick it up, validate the dataset file(s) are available,
**          and submit back to DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   10/03/2007 jds - Initial version
**          04/26/2010 grk - widened @Dataset_Name to 128 characters
**          02/03/2011 mem - Now calling xml_quote_check() to replace double quotes with &quot;
**          07/31/2012 mem - Now using combine_paths to build the output file path
**          05/08/2013 mem - Removed IsNull() checks since xml_quote_check() now changes Nulls to empty strings
**          06/23/2015 mem - Added @Capture_Subfolder
**          02/23/2017 mem - Added @LC_Cart_Config
**          03/15/2017 mem - Log an error if @triggerFolderPath does not exist
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          07/02/2019 mem - Add parameter @workPackage
**          11/25/2022 mem - Rename parameter to @Wellplate
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Look for '..\' at the start of @capture_Subfolder
**                         - Use new XML element names
**
*****************************************************/
(
    @dataset_Name       varchar(128),       -- @datasetName
    @experiment_Name    varchar(64),        -- @experimentName
    @instrument_Name    varchar(64),        -- @instrumentName
    @separation_Type    varchar(64),        -- @secSep
    @lc_Cart_Name       varchar(128),       -- @LCCartName
    @lc_Column          varchar(64),        -- @LCColumnName
    @wellplate_Name     varchar(64),        -- @wellplateName
    @well_Number        varchar(64),        -- @wellNumber
    @dataset_Type       varchar(20),        -- @msType
    @operator_Username  varchar(64),        -- @operatorUsername
    @dsCreator_Username varchar(64),        -- @DScreatorUsername
    @comment            varchar(512),       -- @comment
    @interest_Rating    varchar(32),        -- @rating
    @request            int,                -- @requestID
    @workPackage        varchar(50) = '',
    @emsl_Usage_Type    varchar(50) = '',   -- @eusUsageType
    @emsl_Proposal_ID   varchar(10) = '',   -- @eusProposalID
    @emsl_Users_List    varchar(1024) = '', -- @eusUsersList
    @run_Start          varchar(64),
    @run_Finish         varchar(64),
    @capture_Subfolder  varchar(255),
    @lc_Cart_Config     varchar(128),
    @message            varchar(512) output
)
AS
set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @logErrors tinyint = 0

    If @request Is Null
    Begin
        Set @myError = 70
        Set @message = 'Request is null, cannot create trigger file'
        Goto done
    End

    Set @logErrors = 1

    Declare @fso int
    Declare @hr int
    Declare @src varchar(255), @desc varchar(255)
    Declare @result int

    Declare @triggerFolderPath varchar(100)
    select @triggerFolderPath = server
    from T_MiscPaths
    where [Function] = 'DIMTriggerFileDir'

    -- Create a filesystem object
    EXEC @hr = sp_OACreate 'Scripting.FileSystemObject', @fso OUT
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
        SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
        Set @message = 'Error creating FileSystemObject, cannot create trigger file'
        goto Done
    END

    -- Make sure @triggerFolderPath exists
    EXEC @hr = sp_OAMethod  @fso, 'FolderExists', @result OUT, @triggerFolderPath
    IF @hr <> 0
    BEGIN
        EXEC load_get_oa_error_message @fso, @hr, @message OUT
        set @myError = 72
        If IsNull(@message, '') = ''
            Set @message = 'Error verifying that the trigger folder exists at ' + IsNull(@triggerFolderPath, '??')
        goto DestroyFSO
    END

    If @result = 0
    Begin
        set @myError = 74
        Set @message = 'Trigger folder not found at ' + IsNull(@triggerFolderPath, '??') + '; update T_MiscPaths'
        goto DestroyFSO
    End

    Declare @filePath varchar(150) = dbo.combine_paths(@triggerFolderPath, 'man_' + @dataset_Name + '.xml')

    Declare @xmlLine varchar(50) = ''

    Set @capture_Subfolder = IsNull(@capture_Subfolder, '')
    Set @lc_Cart_Config = IsNull(@lc_Cart_Config, '')

    Declare @captureShareName Varchar(255)
    Declare @captureSubdirectory Varchar(255)
    Declare @charPos Int

    If @capture_Subfolder Like '..\%\%'
    Begin
        -- Find the second backslash
        Set @charPos = CharIndex('\', @capture_Subfolder, 4)

        If @charPos > 4
        Begin
            Set @captureShareName = Substring(@capture_Subfolder, 4, @charPos - 4)
            Set @captureSubdirectory = Substring(@capture_Subfolder, @charPos + 1, 250)
        End
        Else
        Begin
            Set @captureShareName = ''
            Set @captureSubdirectory = @capture_Subfolder
        End
    End
    Else
    Begin
        Set @captureShareName = ''
        Set @captureSubdirectory = @capture_Subfolder
    End

    set @message = ''

    ---------------------------------------------------
    -- Create XML dataset trigger file lines
    -- Be sure to replace double quote characters with &quot; to avoid mal-formed XML
    -- In reality, only the comment should have double-quote characters, but we'll check all text fields just to be safe
    -- Note that xml_quote_check will also change Null values to empty strings
    ---------------------------------------------------
    --
    Declare @tmpXmlLine varchar(4000)
    Declare @newLine varchar(2) = char(13) + char(10)

    --XML Header
    set @tmpXmlLine = '<?xml version="1.0" ?>' + @newLine

    set @tmpXmlLine = @tmpXmlLine + '<Dataset>' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Dataset Name" Value="' +            dbo.xml_quote_check(@dataset_Name) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Experiment Name" Value="' +         dbo.xml_quote_check(@experiment_Name) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Instrument Name" Value="' +         dbo.xml_quote_check(@instrument_Name) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Capture Share Name" Value=""' +     dbo.xml_quote_check(@captureShareName) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Capture Subdirectory" Value="' +    dbo.xml_quote_check(@captureSubdirectory) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Separation Type" Value="' +         dbo.xml_quote_check(@separation_Type) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="LC Cart Name" Value="' +            dbo.xml_quote_check(@lc_Cart_Name) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="LC Cart Config" Value="' +          dbo.xml_quote_check(@lc_Cart_Config) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="LC Column" Value="' +               dbo.xml_quote_check(@lc_Column) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Wellplate Name" Value="' +          dbo.xml_quote_check(@wellplate_Name) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Well Number" Value="' +             dbo.xml_quote_check(@well_Number) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Dataset Type" Value="' +            dbo.xml_quote_check(@dataset_Type) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Operator (Username)" Value="' +     dbo.xml_quote_check(@operator_Username) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="DS Creator (Username)" Value="' +   dbo.xml_quote_check(@dsCreator_Username) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Work Package" Value="' +            dbo.xml_quote_check(@workPackage) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Comment" Value="' +                 dbo.xml_quote_check(@comment) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Interest Rating" Value="' +         dbo.xml_quote_check(@interest_Rating) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Request" Value="' +                 cast(@request as varchar(32)) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="EMSL Proposal ID" Value="' +        dbo.xml_quote_check(@emsl_Proposal_ID) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="EMSL Usage Type" Value="' +         dbo.xml_quote_check(@emsl_Usage_Type) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="EMSL Users List" Value="' +         dbo.xml_quote_check(@emsl_Users_List) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Run Start" Value="' +               dbo.xml_quote_check(@run_Start) + '" />' + @newLine
    set @tmpXmlLine = @tmpXmlLine + '  <Parameter Name="Run Finish" Value="' +              dbo.xml_quote_check(@run_Finish) + '" />' + @newLine

    --Close XML file
    set @tmpXmlLine = @tmpXmlLine + '</Dataset>' + @newLine

    ---------------------------------------------------
    -- write XML dataset trigger file
    ---------------------------------------------------

    Declare @ts int
    Declare @property varchar(255)
    Declare @return varchar(255)

    -- see if file already exists
    --
    EXEC @hr = sp_OAMethod  @fso, 'FileExists', @result OUT, @filePath
    IF @hr <> 0
    BEGIN
        EXEC load_get_oa_error_message @fso, @hr, @message OUT
        set @myError = 76
        If IsNull(@message, '') = ''
            Set @message = 'Error looking for an existing trigger file at ' + IsNull(@filePath, '??')
        goto DestroyFSO
    END

    If @result = 1
    begin
        Set @logErrors = 0
        set @message = 'Trigger file already exists (' + @filePath + ').  Enter a different dataset name'
        set @myError = 78
        goto DestroyFSO
    end

    -- Open the text file for appending (1- ForReading, 2 - ForWriting, 8 - ForAppending)
    EXEC @hr = sp_OAMethod @fso, 'OpenTextFile', @ts OUT, @filePath, 8, true
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
        SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
        set @myError = 80
        If IsNull(@message, '') = ''
            Set @message = 'Error creating the trigger file at ' + IsNull(@filePath, '??')
        goto DestroyFSO
    END

    -- call the write method of the text stream to write the trigger file
    EXEC @hr = sp_OAMethod @ts, 'WriteLine', NULL, @tmpXmlLine
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
        SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
        set @myError = 82
        If IsNull(@message, '') = ''
            Set @message = 'Error writing to the trigger file at ' + IsNull(@filePath, '??')
        goto DestroyFSO
    END

    -- Close the text stream
    EXEC @hr = sp_OAMethod @ts, 'Close', NULL
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
        SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
        set @myError = 84
        If IsNull(@message, '') = ''
            Set @message = 'Error closing the trigger file at ' + IsNull(@filePath, '??')
        goto DestroyFSO
    END

    return 0

    -----------------------------------------------
    -- clean up file system object
    -----------------------------------------------

DestroyFSO:
    -- Destroy the FileSystemObject object.
    --
    EXEC @hr = sp_OADestroy @fso
    IF @hr <> 0
    BEGIN
        EXEC load_get_oa_error_message @fso, @hr, @message OUT
        set @myError = 86
        Set @message = 'Error destroying FileSystemObject'
        goto done
    END

    -----------------------------------------------
    -- Exit
    -----------------------------------------------

Done:
    If @myError <> 0
    Begin
        If IsNull(@message, '') = ''
            Set @message = 'Error code ' + Cast(@myError as varchar(9)) + ' in create_xml_dataset_trigger_file'

        If @logErrors > 0
            Exec post_log_entry 'Error', @message, 'create_xml_dataset_trigger_file'
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_xml_dataset_trigger_file] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_xml_dataset_trigger_file] TO [Limited_Table_Write] AS [dbo]
GO
