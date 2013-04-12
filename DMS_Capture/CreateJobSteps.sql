/****** Object:  StoredProcedure [dbo].[CreateJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CreateJobSteps
/****************************************************
**
**	Desc: 
**    Make entries in job steps table and job step 
**    dependency table for each newly added job
**    according to definition of script for that job
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/14/2010 grk - Removed path ID fields
**			05/25/2011 mem - Updated call to CreateStepsForJob
**			04/09/2013 mem - Added additional comments
**    
*****************************************************/
(
	@message varchar(512) output,
	@DebugMode tinyint = 0,							-- When setting this to 1, you can optionally specify a job using @existingJob to view the steps that would be created for that job
	@mode varchar(32) = 'CreateFromImportedJobs',	-- Modes: CreateFromImportedJobs, ExtendExistingJob, UpdateExistingJob
	@existingJob int = 0,							-- Used if @mode = 'ExtendExistingJob' or @mode = 'UpdateExistingJob'; also used if @DebugMode <> 1
	@extensionScriptNameList varchar(512) = '',
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	set nocount on
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @StepCount int
	declare @StepCountNew int
	set @StepCount= 0
	set @StepCountNew = 0
	
	Declare @MaxJobsToAdd int

	declare @StartTime datetime
	declare @LastLogTime datetime
	declare @StatusMessage varchar(512)	

	Declare @JobCountToProcess int
	Declare @JobsProcessed int
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Set @message = ''
	Set @DebugMode = IsNull(@DebugMode, 0)
	Set @existingJob = IsNull(@existingJob, 0)
	Set @mode = IsNull(@mode, '')
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)
	
	If @mode Not In ('CreateFromImportedJobs', 'ExtendExistingJob', 'UpdateExistingJob')
	Begin
		Set @message = 'Unknown mode: ' + @Mode
		Set @myError = 50001
		Goto Done
	End

	Set @StartTime = GetDate()
	Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
	Set @LogIntervalThreshold = IsNull(@LogIntervalThreshold, 15)
	Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
	
	If @LogIntervalThreshold = 0
		Set @LoggingEnabled = 1
		
	If @LoopingUpdateInterval < 2
		Set @LoopingUpdateInterval = 2

	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @StatusMessage = 'Entering'
		exec PostLogEntry 'Progress', @StatusMessage, 'CreateJobSteps'
	End

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
		[Results_Folder_Name] varchar(128) NULL,
		Storage_Server varchar(64) NULL,
		Instrument varchar(24) NULL,
		Instrument_Class VARCHAR(32),
		Max_Simultaneous_Captures int NULL
	)

	CREATE INDEX #IX_Jobs_Job ON #Jobs (Job)
	
	CREATE TABLE #Job_Steps (
		[Job] int NOT NULL,
		[Step_Number] int NOT NULL,
		[Step_Tool] varchar(64) NOT NULL,
		[CPU_Load] [smallint] NULL,
		[Dependencies] tinyint NULL ,
		[Filter_Version] smallint NULL,
		[Signature] int NULL,
		[State] tinyint NULL ,
		[Input_Folder_Name] varchar(128) NULL,
		[Output_Folder_Name] varchar(128) NULL,
		[Processor] varchar(128) NULL,
		Special_Instructions varchar(128) NULL,
		Holdoff_Interval_Minutes smallint NOT NULL,
		Retry_Count smallint NOT NULL
	)

	CREATE INDEX #IX_Job_Steps_Job_Step ON #Job_Steps (Job, Step_Number)

	CREATE TABLE #Job_Step_Dependencies (
		[Job_ID] int NOT NULL,
		[Step_Number] int NOT NULL,
		[Target_Step_Number] int NOT NULL,
		[Condition_Test] varchar(50) NULL,
		[Test_Value] varchar(256) NULL,
		[Enable_Only] tinyint NULL
	)

	CREATE INDEX #IX_Job_Step_Dependencies_Job_Step ON #Job_Step_Dependencies (Job_ID, Step_Number)


	CREATE TABLE #Job_Parameters (
		[Job] int NOT NULL,
		[Parameters] xml NULL
	)

	CREATE INDEX #IX_Job_Parameters_Job ON #Job_Parameters (Job)
	
	---------------------------------------------------
	-- Get jobs that need to be processed
	-- into temp table
	---------------------------------------------------
	--
	if @mode = 'CreateFromImportedJobs'
	Begin
		If @MaxJobsToProcess > 0
			Set @MaxJobsToAdd = @MaxJobsToProcess
		Else
			Set @MaxJobsToAdd = 1000000
		
		if @DebugMode = 0 OR (@DebugMode <> 0 And @existingJob = 0)
		Begin
			INSERT INTO #Jobs( 
				Job,
				Priority,
				Script,
				State,
				Dataset,
				Dataset_ID,
				Results_Folder_Name,
				Storage_Server,
				Instrument,
				Instrument_Class,
				Max_Simultaneous_Captures
			)
			SELECT TOP ( @MaxJobsToAdd )
				TJ.Job,
				TJ.Priority,
				TJ.Script,
				TJ.State,
				TJ.Dataset,
				TJ.Dataset_ID,
				TJ.Results_Folder_Name,
				VDD.Storage_Server_Name,
				VDD.Instrument_Name,
				VDD.Instrument_Class,
				VDD.Max_Simultaneous_Captures
			FROM
				T_Jobs TJ
				INNER JOIN V_DMS_Get_Dataset_Definition AS VDD ON TJ.Dataset_ID = VDD.Dataset_ID
			WHERE
				TJ.State = 0	
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to get jobs for processing'
				goto Done
			end
		End

		If @DebugMode <> 0 And @existingJob <> 0
		Begin
		   INSERT INTO #Jobs
		  ( Job,
			Priority,
			Script,
			State,
			Dataset,
			Dataset_ID,
			Results_Folder_Name
		  )
		  SELECT
			Job,
			Priority,
			Script,
			State,
			Dataset,
			Dataset_ID,
			NULL
		  FROM
			T_Jobs
		  WHERE
			Job = @existingJob
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			begin
				set @message = 'Job ' + Convert(varchar(12), @existingJob) + ' not found in T_Jobs; unable to continue debugging'
				set @myError = 50000
				goto Done
			end
		End
	End
	
	---------------------------------------------------
	-- set up to process extension job
	---------------------------------------------------
	--
	/*
	** Code ported over from DMS_Pipeline but not implemented in DMS_Capture
	**

	if @mode = 'ExtendExistingJob'
	begin
		-- populate #jobs with info from existing job
		-- if it only exists in history, restore it to main tables
		exec @myError = SetUpToExtendExistingJob @existingJob, @message
	end

	if @mode = 'UpdateExistingJob'
	begin
		If Not Exists (SELECT Job FROM T_Jobs Where Job = @existingJob)
		Begin
			Set @message = 'Job ' + Convert(varchar(12), @existingJob) + ' not found in T_Jobs; unable to update it'
			set @myError = 50000
			goto Done
		End
		
		INSERT INTO #Jobs
		SELECT Job, Priority,  Script,  State,  Dataset,  Dataset_ID, Results_Folder_Name
		FROM T_Jobs
		WHERE Job = @existingJob
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to get jobs for processing'
			goto Done
		end
	end
	*/

	---------------------------------------------------
	-- loop through jobs and process them into temp tables
	---------------------------------------------------
	declare @job int
	declare @prevJob int
	declare @scriptName varchar(64)
	declare @resultsFolderName varchar(128)
	declare @datasetID int
	declare @done tinyint
	
	SELECT @JobCountToProcess = COUNT(*)
	FROM #Jobs
	--
	Set @JobCountToProcess = IsNull(@JobCountToProcess, 0)
	
	set @done = 0
	set @prevJob = 0
	Set @JobsProcessed = 0
	Set @LastLogTime = GetDate()
	--
	while @done = 0
	begin --<a>
		---------------------------------------------------
		-- get next unprocessed job and 
		-- build it into the temporary tables
		---------------------------------------------------
		-- 
		set @job = 0
		--
		SELECT TOP 1 
			@job = Job,
			@scriptName = Script,
			@datasetID = Dataset_ID,
			@resultsFolderName = ISNULL(Results_Folder_Name, '')
		FROM 
			#Jobs
		WHERE Job > @prevJob
		ORDER BY Job		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to get next unitiated job'
			goto Done
		end

		---------------------------------------------------
		-- if no job was found, we are done
		-- otherwise, process the job
		---------------------------------------------------
		if @job = 0
			set @done = 1
		else
		begin --<b>
			-- set up to get next job on next pass
			set @prevJob = @job

			declare @pXML xml
			declare @scriptXML xml
			declare @tag varchar(8)
			set @tag = 'unk'

			-- get contents of script and tag for results folder name
			SELECT @scriptXML = Contents, @tag = Results_Tag 
			FROM T_Scripts 
			WHERE Script = @scriptName

			-- add additional scripts, if specified
			if @extensionScriptNameList <> ''
			begin
				declare @scriptXML2 xml
				SELECT @scriptXML2 = Contents FROM T_Scripts WHERE Script = @extensionScriptNameList -- FUTURE: process as list
				set @scriptXML = convert(varchar(2048), @scriptXML) + convert(varchar(2048), @scriptXML2)
			end

			-- get parameters for job (and also store in #Job_Parameters)
			-- Parameters are returned in @pXML (though @pXML is not used by this procedure)
			exec @myError = CreateParametersForJob @job, @datasetID, @pXML output, @message output, @DebugMode = @DebugMode

			-- create the basic job structure (steps and dependencies)
			-- Details are stored in #Job_Steps and #Job_Step_Dependencies
			exec @myError = CreateStepsForJob @job, @scriptXML, @resultsFolderName, @message output

			if @DebugMode <> 0
			begin
				SELECT @StepCount = COUNT(*) FROM #Job_Steps
				SELECT * FROM #Job_Steps
				SELECT * FROM #Job_Step_Dependencies
			end

			-- Perform a mixed bag of operations on the jobs in the temporary tables to finalize them before
			--  copying to the main database tables
			exec @myError = FinishJobCreation @job, @message output
			
			/*
			** Code ported over from DMS_Pipeline but not implemented in DMS_Capture
			**
			
			-- Do current job parameters confilict with existing job?
			if @mode = 'ExtendExistingJob' or @mode = 'UpdateExistingJob'
			begin
				exec @myError = CrossCheckJobParameters @job, @message output
				if @myError <> 0
				Begin
					If @mode = 'UpdateExistingJob'
					Begin
						-- If None of the job steps has completed yet, then it's OK if there are parameter differences
						If Exists (SELECT * FROM T_Job_Steps WHERE Job = @job AND State = 5)
						Begin
							Set @message = 'Conflicting parameters are not allowed when one or more job steps has completed: ' + @message
							Goto Done
						End
						Else
						Begin
							Set @message = ''
							Set @myError = 0
						End
						
					End
					Else
						Goto Done
				End
			end
			*/

			Set @JobsProcessed = @JobsProcessed + 1
		end --<b>
		
		If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
		Begin
			-- Make sure @LoggingEnabled is 1
			Set @LoggingEnabled = 1
			
			Set @StatusMessage = '... Creating job steps: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToProcess)
			exec PostLogEntry 'Progress', @StatusMessage, 'CreateJobSteps'
			Set @LastLogTime = GetDate()
		End

	end --<a>

	---------------------------------------------------
	-- we've got new jobs in temp tables - what to do?
	---------------------------------------------------

	if @DebugMode = 0
	Begin
		if @mode = 'CreateFromImportedJobs'
		begin
			-- Copies data from the following temp tables to actual database tables:
			--	 #Jobs
			--	 #Job_Steps
			--	 #Job_Step_Dependencies
			--	 #Job_Parameters
			exec MoveJobsToMainTables @message output
		end

		/*
		** Code ported over from DMS_Pipeline but not implemented in DMS_Capture
		**

		if @mode = 'ExtendExistingJob'
		begin
			-- merge temp tables with existing job
			exec MergeJobsToMainTables @message output
		end
		
		if @mode = 'UpdateExistingJob'
		begin
			-- merge temp tables with existing job
			exec UpdateJobInMainTables @message output
		end
		**/
	End

	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @LoggingEnabled = 1
		Set @StatusMessage = 'CreateJobSteps complete'
		exec PostLogEntry 'Progress', @StatusMessage, 'CreateJobSteps'
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @StatusMessage = 'Exiting'
		exec PostLogEntry 'Progress', @StatusMessage, 'CreateJobSteps'
	End

	If @DebugMode <> 0
		SELECT * FROM #Jobs

	return @myError

GO
GRANT EXECUTE ON [dbo].[CreateJobSteps] TO [DMS_SP_User] AS [dbo]
GO
