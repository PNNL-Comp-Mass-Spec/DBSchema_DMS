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
**		[Section] Varchar(128),
**		[Name] Varchar(128),
**		[Value] Varchar(max)
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
**    
*****************************************************/
(
	@jobNumber int,
	@stepNumber int,
    @message varchar(512) = '' output,
    @DebugMode tinyint = 0
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	
	declare @stepTool varchar(64) = ''
	declare @inputFolderName varchar(128) = ''
	declare @outputFolderName varchar(128) = ''
	declare @DataPackageID int = 0

	set @myRowCount = 0
	
	-- Clear the outputs
	set @message = ''
	set @DebugMode = IsNull(@DebugMode, 0)
	
	If @DebugMode <> 0
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: Get basic job step parameters'
		
	---------------------------------------------------
	-- Get basic job step parameters
	---------------------------------------------------
	--
	SELECT
		@stepTool = Step_Tool, 
		@inputFolderName = Input_Folder_Name, 
		@outputFolderName = Output_Folder_Name
	FROM  T_Job_Steps
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

	If @DebugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: Get shared results folder name list'

	---------------------------------------------------
	-- Lookup data package ID in T_Jobs
	---------------------------------------------------
	--
	SELECT @DataPackageID = DataPkgID
	FROM T_Jobs 
	WHERE Job = @jobNumber

	Set @DataPackageID = IsNull(@DataPackageID, 0)
	
	---------------------------------------------------
	-- Get shared results folder name list
	-- Be sure to sort by increasing step number so that the newest shared result folder is last
	---------------------------------------------------
	declare @sharedFolderList varchar(1024)
	set @sharedFolderList = Null
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

	If @DebugMode > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: Get job step parameters'

	---------------------------------------------------
	-- get input and output folder names for individual steps
	-- (used by aggregation jobs created in broker)
	---------------------------------------------------

	DECLARE @stepOutputFolderName VARCHAR(128) = ''
	DECLARE @stepInputFolderName VARCHAR(128) = ''

	SELECT  @stepOutputFolderName = 'Step_' + CONVERT(VARCHAR(6), TJS.Step_Number)
			+ '_' + TST.Tag
	FROM    T_Job_Steps TJS
			INNER JOIN T_Step_Tools TST ON TJS.Step_Tool = TST.Name
	WHERE   TJS.Job = @jobNumber
			AND TJS.Step_Number = @stepNumber


	SELECT  @stepInputFolderName = 'Step_'
			+ CONVERT(VARCHAR(6), TSD.Target_Step_Number) + '_' + TST.Tag
	FROM  T_Job_Step_Dependencies AS TSD
			INNER JOIN T_Job_Steps AS TJS ON TSD.Job = TJS.Job
											 AND TSD.Target_Step_Number = TJS.Step_Number
			INNER JOIN T_Step_Tools AS TST ON TJS.Step_Tool = TST.Name
	WHERE   ( TSD.Job = @jobNumber )
			AND ( TSD.Step_Number = @stepNumber )
			AND TSD.Enable_Only = 0

	---------------------------------------------------
	-- Get job step parameters
	---------------------------------------------------
	--
	declare @stepParmSectionName varchar(32)
	set @stepParmSectionName = 'StepParameters'
	--
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Job', @jobNumber)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Step', @stepNumber)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepTool', @stepTool)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'InputFolderName', @inputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'OutputFolderName', @outputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'SharedResultsFolders', @sharedFolderList)

	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepOutputFolderName', @stepOutputFolderName)
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepInputFolderName', @stepInputFolderName)


	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES ('JobParameters', 'DataPackageID', @DataPackageID)


	If @DebugMode <> 0
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'GetJobStepParamsXML: Get job parameters using cross apply'

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
	-- We now use notatio like this:
	--  <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="Yes (2)" />
	--
	-- Thus, the following uses a series of REPLACE commands to remove text from the Step attribute, 
	--  replacing the following three strings with ""
	--   "Yes ("
	--   "No ("
	--   ")"
	
	INSERT INTO #Tmp_JobParamsTable ([Section], [Name], [Value])	
	SELECT Section, Name, [Value]	
	FROM ( SELECT Section,
	              Name,
	              [Value],
	              CASE
	                  WHEN Step = '' THEN 0
	                  WHEN IsNumeric(Step) = 1 THEN Convert(int, Step)
	                  ELSE 0
	              END AS StepNumber
	       FROM ( SELECT xmlNode.value('@Section', 'nvarchar(256)') AS Section,
	                     xmlNode.value('@Name', 'nvarchar(256)') AS Name,
	                     xmlNode.value('@Value', 'nvarchar(4000)') AS [Value],
	                     REPLACE(REPLACE(REPLACE( IsNull(xmlNode.value('@Step', 'nvarchar(128)'), '') , 'Yes (', ''), 'No (', ''), ')', '') AS Step
	              FROM T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
	              WHERE T_Job_Parameters.Job = @jobNumber 
	            ) LookupQ 
	     ) ConvertQ
	WHERE Name <> 'DataPackageID' AND
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
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsWork] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsWork] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParamsWork] TO [PNL\D3M580] AS [dbo]
GO
