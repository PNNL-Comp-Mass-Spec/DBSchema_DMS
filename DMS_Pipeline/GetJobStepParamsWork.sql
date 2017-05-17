/****** Object:  StoredProcedure [dbo].[GetJobStepParamsWork] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetJobStepParamsWork
/****************************************************
**
**	Desc:
**    Populates temporary table #Tmp_JobParamsTable
**	  with the parameters for the given job and step
**
**	Note: Data comes from table T_Job_Parameters in the DMS_Pipeline DB, not from DMS5
**
**
**	The calling procedure must create temporary table #Tmp_JobParamsTable 
**	
**	Create Table #Tmp_JobParamsTable (
**		[Section] varchar(128),
**		[Name] varchar(128),
**		[Value] varchar(max)
**	)
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			12/04/2009 mem - Extracted code from GetJobStepParams to create this procedure
**			07/01/2010 mem - Now constructing a comma separated list of shared result folders instead of just returning the first one
**			10/11/2011 grk - Added step input and output folders
**			01/19/2012 mem - Now adding DataPackageID
**			07/09/2012 mem - Updated to support the "step" attribute of a "param" element containing Yes and a number, for example "Yes (3)"
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			02/16/2015 mem - Now storing T_Step_Tools.Param_File_Storage_Path if defined
**			11/20/2015 mem - Now including CPU_Load
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**			06/20/2016 mem - Update procedure name shown when using @debugMode
**			05/13/2017 mem - Include info from T_Remote_Info if Remote_Info_ID is not 1
**			05/15/2017 mem - Include Remote_Timestamp if defined
**    
*****************************************************/
(
	@jobNumber int,
	@stepNumber int,
    @message varchar(512) = '' output,
    @debugMode tinyint = 0
)
AS
	set nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	Declare @stepTool varchar(64) = ''
	Declare @inputFolderName varchar(128) = ''
	Declare @outputFolderName varchar(128) = ''
	
	Declare @dataPackageID int = 0

	Declare @remoteInfoId int
	Declare @remoteInfo varchar(900) = ''

	Declare @remoteTimestamp varchar(24)
	
	set @myRowCount = 0
	
	-- Clear the outputs
	set @message = ''
	set @debugMode = IsNull(@debugMode, 0)
	
	If @debugMode <> 0
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsWork: Get basic job step parameters'
		
	---------------------------------------------------
	-- Get basic job step parameters
	---------------------------------------------------
	--
	SELECT
		@stepTool = Step_Tool, 
		@inputFolderName = Input_Folder_Name, 
		@outputFolderName = Output_Folder_Name,
		@remoteInfoId = Remote_Info_ID,
		@remoteTimestamp = Remote_Timestamp
	FROM T_Job_Steps
	WHERE
		Job = @jobNumber AND 
		Step_Number = @stepNumber
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting basic job step parameters'
		goto Done
	end
	--
	if @myRowCount = 0
	begin
		set @myError = 42
		set @message = 'Could not find basic job step parameters'
		goto Done
	end

	If @debugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsWork: Get shared results folder name list'

	---------------------------------------------------
	-- Lookup data package ID in T_Jobs
	---------------------------------------------------
	--
	SELECT @dataPackageID = DataPkgID
	FROM T_Jobs 
	WHERE Job = @jobNumber

	Set @dataPackageID = IsNull(@dataPackageID, 0)
	
	---------------------------------------------------
	-- Lookup server info in T_Remote_Info if @remoteInfoId > 1
	---------------------------------------------------
	--
	If IsNull(@remoteInfoId, 0) > 1
	Begin		
		SELECT @remoteInfo = Remote_Info
		FROM T_Remote_Info 
		WHERE Remote_Info_ID = @remoteInfoId

		Set @remoteInfo = IsNull(@remoteInfo, '')
	End
	
	---------------------------------------------------
	-- Get shared results folder name list
	-- Be sure to sort by increasing step number so that the newest shared result folder is last
	---------------------------------------------------
	Declare @sharedFolderList varchar(1024) = Null
	--
	SELECT @sharedFolderList = COALESCE(@sharedFolderList + ', ', 
	                                    ISNULL(@sharedFolderList, '')) + 
	                           Output_Folder_Name
	FROM T_Job_Steps
	WHERE (Job = @jobNumber) AND
	      (Shared_Result_Version > 0) AND
	      (State IN (3, 5))
	ORDER BY Step_Number
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting shared folder name list'
		goto Done
	end

	If @debugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsWork: Get job step parameters'

	---------------------------------------------------
	-- Get input and output folder names for individual steps
	-- (used by aggregation jobs created in broker)
	-- Also lookup the parameter file storage path and the CPU_Load
	---------------------------------------------------

	Declare @stepOutputFolderName varchar(128) = ''
	Declare @stepInputFolderName varchar(128) = ''
	Declare @paramFileStoragePath varchar(256) = ''
	Declare @CpuLoad int = 1
	
	SELECT @stepOutputFolderName = 'Step_' + CONVERT(varchar(6), JS.Step_Number) + '_' + ST.Tag,
	       @paramFileStoragePath = ST.Param_File_Storage_Path,
	       @CpuLoad = JS.CPU_Load
	FROM T_Job_Steps JS
	     INNER JOIN T_Step_Tools ST
	       ON JS.Step_Tool = ST.Name
	WHERE JS.Job = @jobNumber AND
	      JS.Step_Number = @stepNumber


	SELECT @stepInputFolderName = 'Step_' + CONVERT(varchar(6), TSD.Target_Step_Number) + '_' + ST.Tag
	FROM T_Job_Step_Dependencies AS TSD
	     INNER JOIN T_Job_Steps AS JS
	       ON TSD.Job = JS.Job AND
	          TSD.Target_Step_Number = JS.Step_Number
	     INNER JOIN T_Step_Tools AS ST
	       ON JS.Step_Tool = ST.Name
	WHERE (TSD.Job = @jobNumber) AND
	      (TSD.Step_Number = @stepNumber) AND
	      TSD.Enable_Only = 0

	---------------------------------------------------
	-- Get job step parameters
	---------------------------------------------------
	--
	Declare @stepParmSectionName varchar(32) = 'StepParameters'
	--
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Job', @jobNumber)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Step', @stepNumber)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepTool', @stepTool)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'InputFolderName', @inputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'OutputFolderName', @outputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'SharedResultsFolders', @sharedFolderList)

	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepOutputFolderName', @stepOutputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepInputFolderName', @stepInputFolderName)

	If IsNull(@paramFileStoragePath, '') <> ''
	Begin
		INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'ParamFileStoragePath', @paramFileStoragePath)
	End
	
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'CPU_Load', @CpuLoad)

	If IsNull(@remoteInfo, '') <> ''
	Begin
		INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'RemoteInfo', @remoteInfo)
	End

	If IsNull(@remoteTimestamp, '') <> ''
	Begin
		INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Remote_Timestamp', @remoteTimestamp)
	End
	
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES ('JobParameters', 'DataPackageID', @dataPackageID)
	
	If @debugMode <> 0
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsWork: Get job parameters using cross apply'

	---------------------------------------------------
	-- Get job parameters
	-- Exclude DataPackageID since we obtained that from T_Jobs
	---------------------------------------------------
	--
	-- To allow for more than one instance of a tool in a single script, 
	--  look at parameters in sections that either are not locked to any step (step number is null) 
	--  or are locked to the current step
	--
	-- Prior to June 2012, step locking would use notation like this:
	--  <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="2" />
	--
	-- We now use notation like this:
	--  <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="Yes (2)" />
	--
	-- Thus, the following uses a series of REPLACE commands to remove text from the Step attribute, 
	--  replacing the following three strings with ""
	--   "Yes ("
	--   "No ("
	--   ")"
	
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], [Value])	
	SELECT [Section], [Name], [Value]	
	FROM ( SELECT [Section],
	              [Name],
	              [Value],
	              IsNull(Try_Convert(int, Step), 0) AS StepNumber
	       FROM ( SELECT xmlNode.value('@Section', 'nvarchar(256)') AS [Section],
	                     xmlNode.value('@Name', 'nvarchar(256)') AS [Name],
	                     xmlNode.value('@Value', 'nvarchar(4000)') AS [Value],
	     REPLACE(REPLACE(REPLACE( IsNull(xmlNode.value('@Step', 'nvarchar(128)'), '') , 'Yes (', ''), 'No (', ''), ')', '') AS Step
	              FROM T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
	              WHERE T_Job_Parameters.Job = @jobNumber 
	            ) LookupQ 
	     ) ConvertQ
	WHERE [Name] <> 'DataPackageID' AND
	      (StepNumber = 0 OR
	       StepNumber = @stepNumber)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting job parameters'
		goto Done
	end

Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsWork] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsWork] TO [Limited_Table_Write] AS [dbo]
GO
