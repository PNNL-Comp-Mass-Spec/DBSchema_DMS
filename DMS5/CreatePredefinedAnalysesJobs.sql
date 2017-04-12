/****** Object:  StoredProcedure [dbo].[CreatePredefinedAnalysesJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE CreatePredefinedAnalysesJobs
/****************************************************
** 
**	Desc: Schedules analysis jobs for dataset according to defaults
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
**			02/29/2008 mem - Added optional parameter @callingUser; If provided, then will call AlterEventLogEntryUser (Ticket #644)
**			04/11/2008 mem - Now passing @RaiseErrorMessages to EvaluatePredefinedAnalysisRules
**			05/14/2009 mem - Added parameters @AnalysisToolNameFilter, @ExcludeDatasetsNotReleased, and @infoOnly
**			07/22/2009 mem - Improved error reporting for non-zero return values from EvaluatePredefinedAnalysisRules
**			07/12/2010 mem - Expanded protein Collection fields and variables to varchar(4000)
**			08/26/2010 grk - This was cloned from SchedulePredefinedAnalyses; added try-catch error handling 
**			08/26/2010 mem - Added output parameter @JobsCreated
**			02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**			04/11/2011 mem - Updated call to AddUpdateAnalysisJob
**			04/26/2011 mem - Now sending @PreventDuplicatesIgnoresNoExport = 0 to AddUpdateAnalysisJob
**			05/03/2012 mem - Added support for the Special Processing field
**			08/02/2013 mem - Removed extra semicolon in status message
**			06/24/2015 mem - Now passing @infoOnly to AddUpdateAnalysisJob
**			02/23/2016 mem - Add set XACT_ABORT on
**          07/21/2016 mem - Log errors in PostLogEntry
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@callingUser varchar(128) = '',
	@AnalysisToolNameFilter varchar(128) = '',		-- Optional: if not blank, then only considers predefines that match the given tool name (can contain wildcards)
	@ExcludeDatasetsNotReleased tinyint = 1,		-- When non-zero, then excludes datasets with a rating of -5 (we always exclude datasets with a rating < 2 but <> -10)	
	@PreventDuplicateJobs tinyint = 1,				-- When non-zero, then will not create new jobs that duplicate old jobs
	@infoOnly tinyint = 0,
	@message VARCHAR(max) output,
	@JobsCreated int = 0 output
)
As
	Set XACT_ABORT, nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Set @message = ''

	Declare @ErrorMessage varchar(512)
	Declare @NewMessage varchar(512)
    Declare @logMessage varchar(512)
    	
	Declare @CreateJob tinyint = 1
	Declare @JobFailCount int = 0
	Declare @JobFailErrorCode int = 0
	
	Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')
	Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
	Set @PreventDuplicateJobs = IsNull(@PreventDuplicateJobs, 1)
	Set @infoOnly = IsNull(@infoOnly, 0)

	BEGIN TRY
	
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
		proteinCollectionList varchar(4000),
		proteinOptionsList varchar(256), 
		ownerPRN varchar(128),
		comment varchar(128),
		associatedProcessorGroup varchar(64),
		numJobs int,
		propagationMode tinyint,
		specialProcessing varchar(512),
		ID int IDENTITY (1, 1) NOT NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Could not create temporary table'
		RAISERROR (@message, 11, 10)
	End
	
	---------------------------------------------------
	-- Populate the job holding table (#JX)
	---------------------------------------------------
	Declare @result int

	exec @result = EvaluatePredefinedAnalysisRules @datasetNum, 'Export Jobs', @message output, @RaiseErrorMessages=0, @ExcludeDatasetsNotReleased=@ExcludeDatasetsNotReleased
	--
	If @result <> 0
	Begin
		Set @ErrorMessage = 'EvaluatePredefinedAnalysisRules returned error code ' + Convert(varchar(12), @result)
	
		If Not IsNull(@message, '') = ''
			Set @ErrorMessage = @ErrorMessage + '; ' + @message
		
		Set @message = @ErrorMessage
		RAISERROR (@message, 11, 11)
	End

	---------------------------------------------------
	-- Cycle through the job holding table and
	-- make jobs for each entry
	---------------------------------------------------

	Declare @instrumentClass varchar(32)
	Declare @priority int
	Declare @analysisToolName varchar(64)
	Declare @parmFileName varchar(255)
	Declare @settingsFileName varchar(255)
	Declare @organismName varchar(64)
	Declare @organismDBName varchar(64)
	Declare @proteinCollectionList varchar(4000)
	Declare @proteinOptionsList varchar(256)
	Declare @comment varchar(128)
	Declare @propagationMode tinyint
	Declare @propagationModeText varchar(24)
	Declare @specialProcessing varchar(512)
		
	Declare @jobNum varchar(32)
	Declare @ownerPRN varchar(32)
	
	Declare @associatedProcessorGroup varchar(64)
	Set @associatedProcessorGroup = ''

	-- keep track of how many jobs have been scheduled
	--
	Set @jobsCreated = 0
	
	Declare @done tinyint
	Set @done = 0
	
	Declare @currID int
	Set @currID = 0

	While @done = 0 and @myError = 0
	Begin -- <a>
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
			@propagationMode = propagationMode,
			@specialProcessing = specialProcessing,
			@currID = ID
		FROM #JX
		WHERE ID > @currID
		ORDER BY ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Evaluate terminating conditions
		---------------------------------------------------
		--
		If @myError <> 0 OR @myRowCount <> 1
			Set @done = 1
		Else
		Begin -- <b>
		
			If @AnalysisToolNameFilter = ''
				Set @CreateJob = 1
			Else
			Begin
				If @AnalysisToolName Like @AnalysisToolNameFilter
					Set @CreateJob = 1
				Else
					Set @CreateJob = 0
			End

			If IsNull(@propagationMode, 0) = 0
				Set @propagationModeText = 'Export'
			Else
				Set @propagationModeText = 'No Export'
			
			If @CreateJob <> 0
			Begin -- <c>
			
				If @infoOnly <> 0
				Begin
					Print ''
					Print 'Call AddUpdateAnalysisJob for dataset ' + @datasetNum + ' and tool ' + @analysisToolName + '; param file: ' + IsNull(@parmFileName, '') + '; settings file: ' + IsNull(@settingsFileName, '')
				End

				---------------------------------------------------
				-- create the job
				---------------------------------------------------
				execute @result = AddUpdateAnalysisJob
							@datasetNum = @datasetNum,
							@priority = @priority,
							@toolName = @analysisToolName,
							@parmFileName = @parmFileName,
							@settingsFileName = @settingsFileName,
							@organismName = @organismName,
							@protCollNameList = @proteinCollectionList,
							@protCollOptionsList = @proteinOptionsList,
							@organismDBName = @organismDBName,
							@ownerPRN = @ownerPRN,
							@comment = @comment,
							@associatedProcessorGroup = @associatedProcessorGroup,
							@propagationMode = @propagationModeText,
							@stateName = 'new',
							@jobNum = @jobNum output,
							@mode = 'add',				
							@message = @NewMessage output,
							@callingUser = @callingUser,
							@PreventDuplicateJobs = @PreventDuplicateJobs,
							@PreventDuplicatesIgnoresNoExport = 0,
							@specialProcessing = @specialProcessing,
							@SpecialProcessingWaitUntilReady = 1,
							@infoOnly = @infoOnly

				-- If there was an error creating the job, remember it
				-- otherwise bump the job count
				--
				If @result = 0 
				Begin
					If @infoOnly = 0
						Set @jobsCreated = @jobsCreated + 1 
				End
				Else 
				Begin -- <d>
					If @message = ''
						Set @message = @NewMessage
					Else
						Set @message = @message + '; ' + @NewMessage
					
					-- ResultCode 52500 means a duplicate job exists; that error can be ignored					
					If @result <> 52500
					Begin -- <e>
						-- Append the @result ID to @message
						-- Increment @JobFailCount, but keep trying to create the other predefined jobs for this dataset
						Set @JobFailCount = @JobFailCount + 1
						If @JobFailErrorCode = 0
							Set @JobFailErrorCode = @result
							
						Set @message = @message + ' [' + convert(varchar(12), @result) + ']'
						
						Set @logMessage = @NewMessage + '; Dataset ' + @datasetNum + ', Tool ' + @analysisToolName
						exec PostLogEntry 'Error', @logMessage
					End -- </e>
					
				End -- </d>
			
			End -- </c>
		End -- </b>
		
	End -- </b>

	---------------------------------------------------
	-- Construct the summary message
	---------------------------------------------------
	--
	Set @NewMessage = 'Created ' + convert(varchar(12), @jobsCreated) + ' job'
	If @jobsCreated <> 1
		Set @NewMessage = @NewMessage + 's'
	
	If @message <> ''
	Begin
		-- @message might look like this: Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
		-- If it does, then update @message to remove the dataset name
		
		Set @message = Replace(@message, 'does not allow creation of jobs: ' + @datasetNum, 'does not allow creation of jobs')
		
		Set @NewMessage = @NewMessage + '; ' + @message
	End
	
	Set @message = @NewMessage

	If @JobFailCount > 0 and @myError = 0
	Begin
		If @JobFailErrorCode <> 0
			Set @myError = @JobFailErrorCode
		Else
			Set @myError = 2
	End
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Exec PostLogEntry 'Error', @message, 'CreatePredefinedAnalysesJobs'
	END CATCH
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CreatePredefinedAnalysesJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreatePredefinedAnalysesJobs] TO [Limited_Table_Write] AS [dbo]
GO
