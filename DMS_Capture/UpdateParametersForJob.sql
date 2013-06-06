/****** Object:  StoredProcedure [dbo].[UpdateParametersForJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateParametersForJob
/****************************************************
**
**	Desc: 
**		Update parameters for one or more jobs
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	12/16/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/14/2010 grk - removed path ID fields
**			01/28/2010 grk - modified to use CreateParametersForJob, and to take list of jobs
**			04/13/2010 mem - Fixed bug that didn't properly update T_Job_Parameters when #Job_Parameters contains multiple jobs (because @jobList contained multiple jobs)
**						   - Added support for jobs being present in T_Jobs but not present in T_Job_Parameters
**			05/18/2011 mem - Updated @jobList to varchar(max)
**			09/17/2012 mem - Now updating Storage_Server in T_Jobs if it differs from V_DMS_Capture_Job_Parameters
**    
*****************************************************/
(
	@jobList varchar(max),
	@message varchar(512) = '' output,
	@DebugMode tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- create temp table for jobs that are being updated
	-- and populate it
	-- (needed by call to GetJobParamTable which CreateParametersForJob calls)
	---------------------------------------------------
	--
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
	--
	INSERT INTO #Jobs ( 
		[Job],
		[Priority],
		[Script],
		[State],
		[Dataset],
		[Dataset_ID],
		[Results_Folder_Name],
		Storage_Server,
		Instrument,
		Instrument_Class,
		Max_Simultaneous_Captures
	)
	SELECT
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
	FROM
		T_Jobs
	WHERE
		Job IN (select CONVERT(INT, Item) AS Job FROM dbo.MakeTableFromList(@jobList))

	---------------------------------------------------
	-- temp table to accumulate XML parameters for
	-- jobs in list
	-- (parameters for jobs will be added by CreateParametersForJob)
	---------------------------------------------------
	--
	CREATE TABLE #Job_Parameters (
		[Job] int NOT NULL,
		[Parameters] xml NULL
	)

	IF @DebugMode = 0
	Begin
		-- Update the Storage Server stored in T_Jobs if it differs from V_DMS_Capture_Job_Parameters
		--
		UPDATE T_Jobs
		SET Storage_Server = DCJP.Storage_Server_Name
		FROM T_Jobs
				INNER JOIN V_DMS_Capture_Job_Parameters DCJP
				ON T_Jobs.Dataset_ID = DCJP.Dataset_ID
				INNER JOIN #Jobs
				ON #Jobs.Job = T_Jobs.Job
		WHERE IsNull(DCJP.Storage_Server_Name, '') <> '' AND IsNull(T_Jobs.Storage_Server, '') <> DCJP.Storage_Server_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
			
	---------------------------------------------------
	-- loop through jobs and accumulate parameters
	-- into temp table
	---------------------------------------------------
	--
	declare @job int
	declare @prevJob int
	declare @datasetID int
	declare @scriptName varchar(64)
	declare @done tinyint
	
	set @done = 0
	set @prevJob = 0
	--
	while @done = 0
	begin --<a>
		-- 
		set @job = 0
		--
		SELECT TOP 1 
			@job = Job,
			@datasetID = Dataset_ID,
			@scriptName = Script
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
		-- otherwise, get parameters for job
		---------------------------------------------------
		if @job = 0
			set @done = 1
		else
		begin --<b>
			-- set up to get next job on next pass
			set @prevJob = @job

			declare @pXML XML

			-- get parameters for job (and also store in temp table #Job_Parameters)
			-- Parameters are returned in @pXML
			exec @myError = CreateParametersForJob @job, @datasetID, @scriptName, @pXML output, @message output, @DebugMode = @DebugMode

		end --<b>
	end --<a>

	---------------------------------------------------
	-- replace params in T_Job_Parameters (or output debug message)
	---------------------------------------------------
	--
	IF @DebugMode > 0
	BEGIN 
		SELECT
			Job,
			CONVERT(VARCHAR(4096), [Parameters]) AS Params
		FROM
			#Job_Parameters
	END
	ELSE
	BEGIN
		-- Update existing jobs in T_Job_Parameters
		--
		UPDATE T_Job_Parameters
		SET Parameters = Source.Parameters
		FROM T_Job_Parameters Target
		     INNER JOIN #Job_Parameters Source
		       ON Target.Job = Source.Job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		
		-- Add any missing jobs
		--
		INSERT INTO T_Job_Parameters( Job,
		                              Parameters )
		SELECT Source.Job,
		       Source.Parameters
		FROM #Job_Parameters Source
		     LEFT OUTER JOIN T_Job_Parameters
		       ON Source.Job = T_Job_Parameters.Job
		WHERE T_Job_Parameters.Job IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		    
	END

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
