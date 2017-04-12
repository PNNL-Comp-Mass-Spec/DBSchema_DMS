/****** Object:  StoredProcedure [dbo].[MakeLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeLocalJobInBroker
/****************************************************
**
**	Desc: 
**    Create capture job directly in broker database 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			05/03/2010 grk - Initial release
**			05/25/2011 mem - Updated call to CreateStepsForJob and removed Priority from #Job_Steps
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			05/29/2015 mem - Add support for column Capture_Subfolder
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
	@scriptName varchar(64),
	@priority int,
	@jobParamXML xml,
	@comment varchar(512),
	@DebugMode tinyint = 0,			-- When setting this to 1, you can optionally specify a job using @existingJob to view the steps that would be created for that job	declare @job int
	@job int OUTPUT,
	@resultsFolderName varchar(128) OUTPUT,
	@message varchar(512) output
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_WARNINGS ON
	SET ANSI_PADDING ON

	BEGIN TRY

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
		Instrument_Class VARCHAR(32) NULL,
		Max_Simultaneous_Captures int NULL,
		Capture_Subfolder varchar(255) NULL
	)

--	CREATE INDEX #IX_Jobs_Job ON #Jobs (Job)
	
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

--	CREATE INDEX #IX_Job_Steps_Job_Step ON #Job_Steps (Job, Step_Number)

	CREATE TABLE #Job_Step_Dependencies (
		[Job] int NOT NULL,
		[Step_Number] int NOT NULL,
		[Target_Step_Number] int NOT NULL,
		[Condition_Test] varchar(50) NULL,
		[Test_Value] varchar(256) NULL,
		[Enable_Only] tinyint NULL
	)

--	CREATE INDEX #IX_Job_Step_Dependencies_Job_Step ON #Job_Step_Dependencies (Job, Step_Number)

	CREATE TABLE #Job_Parameters (
		[Job] int NOT NULL,
		[Parameters] xml NULL
	)

--	CREATE INDEX #IX_Job_Parameters_Job ON #Job_Parameters (Job)


	---------------------------------------------------
	-- dataset
	---------------------------------------------------
	
	DECLARE @datasetNum varchar(128)
	declare @datasetID int
	SET @datasetNum = 'na'
	SET @datasetID = 0

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

	---------------------------------------------------
	-- Add job to temp table
	---------------------------------------------------
	--
	INSERT INTO #Jobs
		( Job,
		  Priority,
		  Script,
		  State,
		  Dataset,
		  Dataset_ID,
		  Results_Folder_Name
		)
	VALUES
		( @job,
		  @priority,
		  @scriptName,
		  1,
		  @datasetNum,
		  @datasetID,
		  NULL
		)


	---------------------------------------------------
	-- save job parameters as XML into temp table
	---------------------------------------------------
	-- FUTURE: need to get set of parameters normally provided by GetJobParamTable, 
	-- except for the job specifc ones which need to be provided as initial content of @jobParamXML
	--
	INSERT INTO #Job_Parameters
	(Job, Parameters)
	VALUES (@job, @jobParamXML)


	---------------------------------------------------
	-- create the basic job structure (steps and dependencies)
	-- Details are stored in #Job_Steps and #Job_Step_Dependencies
	---------------------------------------------------
	-- 
	exec @myError = CreateStepsForJob @job, @scriptXML, @resultsFolderName, @message output
		
	---------------------------------------------------
	-- Perform a mixed bag of operations on the jobs 
	-- in the temporary tables to finalize them before
	--  copying to the main database tables
	---------------------------------------------------
	--
	exec @myError = FinishJobCreation @job, @message output

	---------------------------------------------------
	-- transaction
	---------------------------------------------------
	declare @transName varchar(32)
	set @transName = 'MakeLocalJobInBroker'
	
	---------------------------------------------------
	-- move temp tables to main tables
	---------------------------------------------------
	If @DebugMode = 0
	begin

		begin transaction @transName

		-- MoveJobsToMainTables sproc assumes that T_Jobs table entry is already there
		--	
		INSERT INTO T_Jobs
			(
			  Priority,
			  Script,
			  State,
			  Dataset,
			  Dataset_ID,
			  Transfer_Folder_Path,
			  Comment,
			  Storage_Server
			)
		VALUES
			( 
			  @priority,
			  @scriptName,
			  1,
			  @datasetNum,
			  @datasetID,
			  NULL,
			  @comment,
			  NULL
			)
			
		set @job = IDENT_CURRENT('T_Jobs')
		
		UPDATE #Jobs  SET Job = @Job
		UPDATE #Job_Steps  SET Job = @Job
		UPDATE #Job_Step_Dependencies  SET Job = @Job
		UPDATE #Job_Parameters  SET Job = @Job

		exec @myError = MoveJobsToMainTables @message output

		commit transaction @transName
	end

	---------------------------------------------------
	-- FUTURE: commit transaction
	---------------------------------------------------

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @DebugMode <> 0
	begin
		SELECT '#Jobs' AS T, * FROM #Jobs
		SELECT '#Job_Steps' AS T, * FROM #Job_Steps
		SELECT '#Job_Step_Dependencies' AS T, * FROM #Job_Step_Dependencies
		SELECT '#Job_Parameters' AS T, * FROM #Job_Parameters
	end

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'MakeLocalJobInBroker'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MakeLocalJobInBroker] TO [DDL_Viewer] AS [dbo]
GO
