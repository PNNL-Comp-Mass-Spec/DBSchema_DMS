/****** Object:  StoredProcedure [dbo].[SchedulePredefinedAnalyses] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SchedulePredefinedAnalyses
/****************************************************
** 
**	Desc: Schedules analysis jobs for dataset 
**            according to defaults
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**	Date:	06/29/2005 grk - supersedes "ScheduleDefaultAnalyses"
**			03/28/2006 grk - added protein collection fields
**			04/04/2006 grk - increased sized of param file name
**			06/01/2006 grk - fixed calling sequence to AddUpdateAnalysisJob
**			03/15/2007 mem - Updated call to AddUpdateAnalysisJob (Ticket #394)
**						   - Replaced processor name with associated processor group (Ticket #388)
**    
*****************************************************/
(
	@datasetNum varchar(128)
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @message varchar(512)
	set @message = ''

	---------------------------------------------------
	-- Temporary job holding table to receive created jobs
	-- This table is populated in EvaluatePredefinedAnalysisRules
	---------------------------------------------------
	
	CREATE TABLE #JX (
		datasetNum varchar(128),
		priority varchar(8),
		analysisToolName varchar(64),
		parmFileName varchar(255),
		settingsFileName varchar(128),
		organismDBName varchar(128),
		organismName varchar(128),
		proteinCollectionList varchar(512),
		proteinOptionsList varchar(256), 
		ownerPRN varchar(128),
		comment varchar(128),
		associatedProcessorGroup varchar(64),
		numJobs int,
		ID int IDENTITY (1, 1) NOT NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not create temporary table'
		RAISERROR (@message, 10, 1)
		return @myError
	end
	
	---------------------------------------------------
	-- Populate the job holding table (#JX)
	---------------------------------------------------
	declare @result int

	exec @result = EvaluatePredefinedAnalysisRules @datasetNum, 'Export Jobs', @message output
	--
	if @result <> 0
	begin
		RAISERROR (@message, 10, 1)
		return 53500
	end

	---------------------------------------------------
	-- Cycle through the job holding table and
	-- make jobs for each entry
	---------------------------------------------------

	declare @instrumentClass varchar(32)
	declare @priority int
	declare @analysisToolName varchar(64)
	declare @parmFileName varchar(255)
	declare @settingsFileName varchar(255)
	declare @organismName varchar(64)
	declare @organismDBName varchar(64)
	declare @proteinCollectionList varchar(512)
	declare @proteinOptionsList varchar(256)
	declare @comment varchar(128)
	declare @ID int

	declare @jobNum varchar(32)
	declare @ownerPRN varchar(32)
	
	declare @associatedProcessorGroup varchar(64)
	set @associatedProcessorGroup = ''

	-- keep track of how many jobs have been scheduled
	--
	declare @jobsCreated int
	set @jobsCreated = 0
	
	declare @done tinyint
	set @done = 0
	
	declare @currID int
	set @currID = 0

	WHILE @done = 0 and @myError = 0
	BEGIN
		---------------------------------------------------
		-- get parameters for next job in table
		---------------------------------------------------
		SELECT TOP 1
			@priority = priority,
			@analysisToolName = analysisToolName,
			@parmFileName = parmFileName,
			@settingsFileName = settingsFileName,
			@organismDBName = organismDBName,
			@organismName = organismName,
			@proteinCollectionList = proteinCollectionList,
			@proteinOptionsList = proteinOptionsList,
			@ownerPRN  = ownerPRN,
			@comment = comment,
			@associatedProcessorGroup = associatedProcessorGroup,
			@ID = ID
		FROM #JX
		WHERE ID > @currID
		ORDER BY ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- remember index and evaluate terminating conditions
		---------------------------------------------------
		set @currID = @ID
		--
		if @myError <> 0 OR @myRowCount <> 1
			begin
				set @done = 1
			end
		else
			begin
				---------------------------------------------------
				-- create the job
				---------------------------------------------------
				execute @result = AddUpdateAnalysisJob
							@datasetNum,
							@priority,
							@analysisToolName,
							@parmFileName,
							@settingsFileName,
							@organismName,
							@proteinCollectionList,
							@proteinOptionsList,
							@organismDBName,
							@ownerPRN,
							@comment,
							@associatedProcessorGroup,
							'',					-- Propagation mode
							'new',				-- State name
							@jobNum output,		-- Job number
							'add',				-- Mode
							@message output

				-- if there was an error creating the job, remember it
				-- otherwise bump the job count
				--
				if @result = 0 
					set @jobsCreated = @jobsCreated + 1 
				else 
					set @myError = @result
			end
			---------------------------------------------------
			-- if there was an error, log it
			---------------------------------------------------
			--
			if @myError <> 0 
			begin
				set @message = 'Attempted and failed to create default analysis for "' + @datasetNum + '" [' + convert(varchar(12), @myError) + ']'
				execute PostLogEntry 'Error', @message, 'ScheduleDefaultAnalyses'
			end
	END
	
	---------------------------------------------------
	-- if we didn't schedule any jobs, 
	-- but didn't have any errors, return code of 1
	---------------------------------------------------
	--
	if @myError = 0 and @jobsCreated = 0 set @myError = 1

Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SchedulePredefinedAnalyses] TO [DMS_Analysis]
GO
