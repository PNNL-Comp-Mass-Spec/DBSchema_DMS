/****** Object:  StoredProcedure [dbo].[ValidateJobServerInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ValidateJobServerInfo
/****************************************************
**
**	Desc:
**		Updates fields Transfer_Folder_Path and Storage_Server in T_Jobs
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	07/12/2011 mem - Initial version
**			11/14/2011 mem - Updated to support Dataset Name being blank
**
*****************************************************/
(
    @Job int,
	@UseJobParameters tinyint = 1,		-- When non-zero, then preferentially uses T_Job_Parameters; otherwise, directly queries DMS
	@message varchar(256) = '',
	@DebugMode tinyint = 0

)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @TransferFolderPath varchar(256)
	Declare @StorageServerName varchar(128)
	Declare @Dataset varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @Job = IsNull(@Job, 0)
	Set @UseJobParameters = IsNull(@UseJobParameters, 1)
	Set @message = ''
	
	Set @TransferFolderPath = ''
	Set @Dataset = ''
	Set @StorageServerName = ''
	
	if @UseJobParameters <> 0
	Begin
		---------------------------------------------------
		-- Query T_Job_Parameters to extract out the transferFolderPath value for this job
		-- The XML we are querying looks like:
		-- <Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
		---------------------------------------------------
		--
		SELECT @TransferFolderPath = [Value]
		FROM dbo.GetJobParamTableLocal ( @Job )
		WHERE [Name] = 'transferFolderPath'
	
		SELECT @Dataset = [Value]
		FROM dbo.GetJobParamTableLocal ( @Job )
		WHERE [Name] = 'DatasetNum'
	
		If @DebugMode <> 0
			Select @Job as Job, @TransferFolderPath as TransferFolder, @Dataset as Dataset, 'T_Job_Parameters' as Source
	End
	
	If IsNull(@TransferFolderPath, '') = ''
	Begin
		---------------------------------------------------
		-- Info not found in T_Job_Parameters
		-- Directly query DMS
		---------------------------------------------------
		--
		declare @Job_Parameters table (
			[Job] int,
			[Step_Number] int,
			[Section] varchar(64),
			[Name] varchar(128),
			[Value] varchar(2000)
		)
		--
		INSERT INTO @Job_Parameters
			(Job, Step_Number, [Section], [Name], Value)
		execute GetJobParamTable @job, @SettingsFileOverride='', @DebugMode=@DebugMode
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		SELECT @TransferFolderPath = Value
		FROM @Job_Parameters
		WHERE Name = 'transferFolderPath'		
			
		SELECT @Dataset = Value
		FROM @Job_Parameters
		WHERE Name = 'DatasetNum'

		If @DebugMode <> 0
			Select @Job as Job, @TransferFolderPath as TransferFolder, @Dataset as Dataset, 'DMS5' as Source
			
	End
		
	If IsNull(@TransferFolderPath, '') <> ''
	Begin
		-- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
		--
		If IsNull(@Dataset, '') <> ''
			Set @TransferFolderPath = dbo.udfCombinePaths(@TransferFolderPath, @Dataset)
		
		If Right(@TransferFolderPath, 1) <> '\'
			Set @TransferFolderPath = @TransferFolderPath + '\'
			
		Set @StorageServerName = dbo.udfExtractServerName(@TransferFolderPath)
		
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
		Exec PostLogEntry 'Error', @message, 'ValidateJobServerInfo'
		Set @myError = 52005
		
		If @DebugMode <> 0
			Select 'Error' as Messsage_Type, @Message as Message
	End
	
	return @myError

GO
