/****** Object:  StoredProcedure [dbo].[validate_job_server_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_job_server_info]
/****************************************************
**
**  Desc:
**      Updates fields Transfer_Folder_Path and Storage_Server in T_Jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          11/14/2011 mem - Updated to support Dataset Name being blank
**          12/21/2016 mem - Use job parameter DatasetFolderName when constructing the transfer folder path
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/22/2023 mem - Rename job parameter to DatasetName
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**
*****************************************************/
(
    @job int,
    @useJobParameters tinyint = 1,      -- When non-zero, then preferentially uses T_Job_Parameters; otherwise, directly queries DMS
    @message varchar(256) = '',
    @debugMode tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @TransferFolderPath varchar(256)
    Declare @StorageServerName varchar(128)
    Declare @Dataset varchar(256)
    Declare @DatasetFolderName varchar(256)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @Job = IsNull(@Job, 0)
    Set @UseJobParameters = IsNull(@UseJobParameters, 1)
    Set @message = ''

    Set @TransferFolderPath = ''
    Set @Dataset = ''
    Set @DatasetFolderName = ''
    Set @StorageServerName = ''

    if @UseJobParameters <> 0
    Begin
        ---------------------------------------------------
        -- Query T_Job_Parameters to extract out the TransferFolderPath value for this job
        -- The XML we are querying looks like:
        -- <Param Section="JobParameters" Name="TransferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
        ---------------------------------------------------
        --
        SELECT @TransferFolderPath = [Value]
        FROM dbo.get_job_param_table_local ( @Job )
        WHERE [Name] = 'TransferFolderPath'

        SELECT TOP 1 @Dataset = [Value]
        FROM dbo.get_job_param_table_local ( @Job )
        WHERE [Name] IN ('DatasetName', 'DatasetNum')
        ORDER BY [Name]

        SELECT @DatasetFolderName = [Value]
        FROM dbo.get_job_param_table_local ( @Job )
        WHERE [Name] = 'DatasetFolderName'

        If @DebugMode <> 0
            Select @Job as Job, @TransferFolderPath as TransferFolder, @Dataset as Dataset, @DatasetFolderName as Dataset_Folder_Path, 'T_Job_Parameters' as Source
    End

    If IsNull(@TransferFolderPath, '') = ''
    Begin
        ---------------------------------------------------
        -- Info not found in T_Job_Parameters (or @UseJobParameters is 0)
        -- Directly query DMS
        ---------------------------------------------------
        --
        Declare @Job_Parameters table (
            [Job] int,
            [Step_Number] int,
            [Section] varchar(64),
            [Name] varchar(128),
            [Value] varchar(2000)
        )
        --
        INSERT INTO @Job_Parameters
            (Job, Step_Number, [Section], [Name], Value)
        execute get_job_param_table @job, @SettingsFileOverride='', @DebugMode=@DebugMode
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        SELECT @TransferFolderPath = Value
        FROM @Job_Parameters
        WHERE [Name] = 'TransferFolderPath'

        SELECT TOP 1 @Dataset = Value
        FROM @Job_Parameters
        WHERE [Name] IN ('DatasetName', 'DatasetNum')
        ORDER BY [Name]

        SELECT @DatasetFolderName = Value
        FROM @Job_Parameters
        WHERE [Name] = 'DatasetFolderName'

        If @DebugMode <> 0
            Select @Job as Job, @TransferFolderPath as TransferFolder, @Dataset as Dataset, @DatasetFolderName as Dataset_Folder_Path, 'DMS5' as Source

    End

    If IsNull(@TransferFolderPath, '') <> ''
    Begin
        -- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
        --
        If IsNull(@DatasetFolderName, '') <> ''
        Begin
            Set @TransferFolderPath = dbo.combine_paths(@TransferFolderPath, @DatasetFolderName)
        End
        Else
        Begin
            If IsNull(@Dataset, '') <> ''
                Set @TransferFolderPath = dbo.combine_paths(@TransferFolderPath, @Dataset)
        End

        If Right(@TransferFolderPath, 1) <> '\'
            Set @TransferFolderPath = @TransferFolderPath + '\'

        Set @StorageServerName = dbo.extract_server_name(@TransferFolderPath)

        UPDATE T_Jobs
        SET Transfer_Folder_Path = @TransferFolderPath,
            Storage_Server = Case When @StorageServerName = ''
                             Then Storage_Server
                             Else @StorageServerName End
        WHERE Job = @Job AND
                (IsNull(Transfer_Folder_Path, '') <> @TransferFolderPath OR
                 IsNull(Storage_Server, '') <> @StorageServerName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @DebugMode <> 0
            Select @Job as Job, @TransferFolderPath as TransferFolder, @Dataset as Dataset, @StorageServerName as Storage_Server, @myRowCount as RowCountUpdated

    End
    Else
    Begin
        Set @message = 'Unable to determine TransferFolderPath and/or Dataset name for job ' + Convert(varchar(12), @job)
        Exec post_log_entry 'Error', @message, 'validate_job_server_info'
        Set @myError = 52005

        If @DebugMode <> 0
            Select 'Error' as Messsage_Type, @Message as Message
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_job_server_info] TO [DDL_Viewer] AS [dbo]
GO
