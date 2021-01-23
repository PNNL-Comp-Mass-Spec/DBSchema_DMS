/****** Object:  StoredProcedure [dbo].[MakeLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MakeLocalJobInBroker]
/****************************************************
**
**	Desc: 
**    Create analysis job directly in broker database 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			04/13/2010 grk - Initial release
**			05/25/2010 grk - All dataset name other than 'na'
**			10/25/2010 grk - Added call to AdjustParamsForLocalJob
**			11/25/2010 mem - Added code to update the Dependencies column in #Job_Steps
**			05/25/2011 mem - Updated call to CreateStepsForJob and removed Priority from #Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			11/14/2011 mem - Now populating column Transfer_Folder_Path in T_Jobs
**			01/09/2012 mem - Added parameter @ownerPRN
**			01/19/2012 mem - Added parameter @dataPackageID
**			02/07/2012 mem - Now validating that @dataPackageID is > 0 when @scriptName is MultiAlign_Aggregator
**			03/20/2012 mem - Now calling UpdateJobParamOrgDbInfoUsingDataPkg
**			08/21/2012 mem - Now including the message text reported by CreateStepsForJob if it returns an error code
**			04/10/2013 mem - Now calling AlterEnteredByUser to update T_Job_Events
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**
*****************************************************/
(
	@scriptName varchar(64),
    @datasetNum varchar(128) = 'na',
	@priority int,
	@jobParamXML xml,
	@comment varchar(512),
	@ownerPRN varchar(64),
	@dataPackageID int,
	@debugMode tinyint = 0,			-- When setting this to 1, you can optionally specify a job using @existingJob to view the steps that would be created for that job
	@job int OUTPUT,
	@resultsFolderName varchar(128) OUTPUT,
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @msg varchar(255) = ''
	
	Set @dataPackageID = IsNull(@dataPackageID, 0)
	Set @scriptName = LTrim(RTrim(IsNull(@scriptName, '')))
	
	---------------------------------------------------
	-- create temporary tables to accumulate job steps
	-- job step dependencies, and job parameters for
	-- jobs being created
	---------------------------------------------------

	CREATE TABLE #Jobs (
		[Job] int NOT NULL,
		[Priority] int NULL,
		[Script] varchar(64) NULL,
		[State] int NOT NULL,
		[Dataset] varchar(128) NULL,
		[Dataset_ID] int NULL,
		[Results_Folder_Name] varchar(128) NULL
	)

	CREATE TABLE #Job_Steps (
		[Job] int NOT NULL,
		[Step_Number] int NOT NULL,
		[Step_Tool] varchar(64) NOT NULL,
		[CPU_Load] [smallint] NULL,
		[Memory_Usage_MB] int NULL,
		[Dependencies] tinyint NULL ,
		[Shared_Result_Version] smallint NULL,
		[Filter_Version] smallint NULL,
		[Signature] int NULL,
		[State] tinyint NULL ,
		[Input_Folder_Name] varchar(128) NULL,
		[Output_Folder_Name] varchar(128) NULL,
		[Processor] varchar(128) NULL,
		Special_Instructions varchar(128) NULL
	)

	CREATE TABLE #Job_Step_Dependencies (
		[Job] int NOT NULL,
		[Step_Number] int NOT NULL,
		[Target_Step_Number] int NOT NULL,
		[Condition_Test] varchar(50) NULL,
		[Test_Value] varchar(256) NULL,
		[Enable_Only] tinyint NULL
	)

	CREATE TABLE #Job_Parameters (
		[Job] int NOT NULL,
		[Parameters] xml NULL
	)

	---------------------------------------------------
	-- script
	---------------------------------------------------
	--
	declare @pXML xml
	declare @scriptXML xml
	declare @tag varchar(8)
	set @tag = 'unk'
	--
	--
	-- get contents of script and tag for results folder name
	SELECT @scriptXML = Contents, @tag = Results_Tag 
	FROM T_Scripts 
	WHERE Script = @scriptName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @myError = 50013
		Set @msg = 'Script not found in T_Scripts: ' + IsNull(@scriptName, '??')
		RAISERROR (@msg, 15, 1)
		return @myError
	End
	
	If @scriptXML Is Null
	Begin
		Set @myError = 50014
		Set @msg = 'Script XML not defined in the Contents field of T_Scripts for script ' + IsNull(@scriptName, '??')
		RAISERROR (@msg, 15, 1)
		return @myError
	End

	If @scriptName IN ('MultiAlign_Aggregator') And @dataPackageID = 0
	Begin
		Set @myError = 50015
		Set @msg = '"Data Package ID" must be positive when using script ' + @scriptName
		RAISERROR (@msg, 15, 1)
		return @myError
	End
	
	---------------------------------------------------
	-- Obtain new job number
	---------------------------------------------------
	--
	exec @job = S_GetNewJobID 'Created in broker'
	--
	if @job = 0
	begin
		Set @myError = 50010
		Set @msg = 'Could not get a valid job number from DMS'
		RAISERROR (@msg, 15, 1)
		return @myError
	end

	---------------------------------------------------
	-- Note: @datasetID needs to be 0
	-- If it is non-zero, then the newly created job will get deleted from
	--  this DB the next time UpdateContext runs, since the system will think
	--  the job no-longer exists in DMS5 and thus should be deleted
	---------------------------------------------------
	
	declare @datasetID int
	SET @datasetID = 0

	---------------------------------------------------
	-- Add job to temp table
	---------------------------------------------------
	--
	INSERT INTO #Jobs (Job, Priority,  Script,  State,  Dataset,  Dataset_ID, Results_Folder_Name)
	VALUES (@job, @priority,  @scriptName,  1,  @datasetNum,  @datasetID, NULL)


	---------------------------------------------------
	-- get results folder name (and store in #Jobs)
	---------------------------------------------------
	-- 
	exec @myError = CreateResultsFolderName @job, @tag, @resultsFolderName output, @message output
	if @myError <> 0
	Begin
		Set @msg = 'Error returned by CreateResultsFolderName: ' + Convert(varchar(12), @myError)
		goto Done
	End
	
	---------------------------------------------------
	-- create the basic job structure (steps and dependencies)
	-- Details are stored in #Job_Steps and #Job_Step_Dependencies
	---------------------------------------------------
	-- 
	exec @myError = CreateStepsForJob @job, @scriptXML, @resultsFolderName, @message output
	if @myError <> 0
	Begin
		Set @msg = 'Error returned by CreateStepsForJob: ' + Convert(varchar(12), @myError)
		If IsNull(@message, '') <> ''
			Set @msg = @msg + '; ' + @message
		goto Done
	End

	
	---------------------------------------------------
	-- do special needs for local jobs that target other jobs
	---------------------------------------------------
	EXEC AdjustParamsForLocalJob
		@scriptName ,
		@datasetNum ,
		@dataPackageID ,
		@jobParamXML OUTPUT,
		@message output

	---------------------------------------------------
	-- Calculate signatures for steps that require them (and also handle shared results folders)
	-- Details are stored in #Job_Steps
	---------------------------------------------------
	--
	exec @myError = CreateSignaturesForJobSteps @job, @jobParamXML, @datasetID, @message output, @debugMode = @debugMode
	if @myError <> 0
	Begin
		Set @msg = 'Error returned by CreateSignaturesForJobSteps: ' + Convert(varchar(12), @myError)
		goto Done
	End

	---------------------------------------------------
	-- save job parameters as XML into temp table
	---------------------------------------------------
	-- FUTURE: need to get set of parameters normally provided by GetJobParamTable, 
	-- except for the job specifc ones which need to be provided as initial content of @jobParamXML
	--
	INSERT INTO #Job_Parameters
	(Job, Parameters)
	VALUES (@job, @jobParamXML)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		Set @myError = 50012
		Set @msg = 'Error copying job param scratch to temp'
		RAISERROR (@msg, 15, 1)
		return @myError
	end
			
	---------------------------------------------------
	-- handle any step cloning
	---------------------------------------------------
	--
	exec @myError = CloneJobStep @job, @jobParamXML, @message output
	if @myError <> 0
	Begin
		Set @msg = 'Error returned by CloneJobStep: ' + Convert(varchar(12), @myError)
		goto Done
	End


	---------------------------------------------------
	-- Update step dependency count (code taken from SP FinishJobCreation)
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET
		Dependencies = T.dependencies
	FROM   
		#Job_Steps INNER JOIN
		(
			SELECT   
			  Step_Number,
			  COUNT(*) AS dependencies
			FROM     
			  #Job_Step_Dependencies
			WHERE    (Job = @job)
			GROUP BY Step_Number
		) AS T
		ON T.Step_Number = #Job_Steps.Step_Number
	WHERE #Job_Steps.Job = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating job step dependency count: ' + Convert(varchar(12), @myError)
		goto Done
	end
	
	---------------------------------------------------
	-- move temp tables to main tables
	---------------------------------------------------
	
	If @debugMode = 0
	begin	
		-- MoveJobsToMainTables sproc assumes that T_Jobs table entry is already there
		--	
		INSERT INTO T_Jobs( Job,
		                    Priority,
		                    Script,
		                    State,
		                    Dataset,
		                    Dataset_ID,
		                    Transfer_Folder_Path,
		                    [Comment],
		                    Storage_Server,
		                    Owner,
		                    DataPkgID )
		VALUES(@job, @priority, @scriptName, 1, 
		       @datasetNum, @datasetID, NULL, 
		       @comment, NULL, @ownerPRN,
		       IsNull(@dataPackageID, 0))

		exec @myError = MoveJobsToMainTables @message output
		
		exec AlterEnteredByUser 'T_Job_Events', 'Job', @job, @callingUser
		
	end


	If @debugMode = 0
	Begin	
		---------------------------------------------------
		-- Populate column Transfer_Folder_Path in T_Jobs
		---------------------------------------------------
		--
		Declare @TransferFolderPath varchar(512) = ''
		
		SELECT @TransferFolderPath = [Value]
		FROM dbo.GetJobParamTableLocal ( @Job )
		WHERE [Name] = 'transferFolderPath'
		
		If IsNull(@TransferFolderPath, '') <> ''
		Begin
			UPDATE T_Jobs
			SET Transfer_Folder_Path = @TransferFolderPath
			WHERE Job = @Job
		End
		
		---------------------------------------------------
		-- If a data package is defined, then update entries for 
		-- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in T_Job_Parameters
		---------------------------------------------------
		--
		If @dataPackageID > 0
		Begin
			Exec UpdateJobParamOrgDbInfoUsingDataPkg @Job, @dataPackageID, @deleteIfInvalid=0, @message=@message output, @callingUser=@callingUser
		End
		
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	if @myError <> 0 and @msg <> ''
	Begin
		RAISERROR (@msg, 15, 1)
	End


	If @debugMode <> 0
	begin
		SELECT * FROM #Jobs
		SELECT * FROM #Job_Steps
		SELECT * FROM #Job_Step_Dependencies
		SELECT * FROM #Job_Parameters

        Declare @jobParams varchar(8000) = Cast(@jobParamXML as varchar(8000))

        If @debugMode > 1
        Begin
            EXEC PostLogEntry 'Debug', @jobParams, 'MakeLocalJobInBroker'
        End
	end

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MakeLocalJobInBroker] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeLocalJobInBroker] TO [Limited_Table_Write] AS [dbo]
GO
