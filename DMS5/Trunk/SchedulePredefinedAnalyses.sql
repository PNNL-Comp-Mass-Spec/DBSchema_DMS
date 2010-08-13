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
**			02/29/2008 mem - Added optional parameter @callingUser; If provided, then will call AlterEventLogEntryUser (Ticket #644)
**			04/11/2008 mem - Now passing @RaiseErrorMessages to EvaluatePredefinedAnalysisRules
**			05/14/2009 mem - Added parameters @AnalysisToolNameFilter, @ExcludeDatasetsNotReleased, and @InfoOnly
**			07/22/2009 mem - Improved error reporting for non-zero return values from EvaluatePredefinedAnalysisRules
**			07/12/2010 mem - Expanded protein Collection fields and variables to varchar(4000)
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@callingUser varchar(128) = '',
	@AnalysisToolNameFilter varchar(128) = '',		-- Optional: if not blank, then only considers predefines that match the given tool name (can contain wildcards)
	@ExcludeDatasetsNotReleased tinyint = 1,		-- When non-zero, then excludes datasets with a rating of -5 (we always exclude datasets with a rating < 2 but <> -10)	
	@InfoOnly tinyint = 0
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	declare @message varchar(512)
	Set @message = ''

	declare @ErrorMessage varchar(512)
	
	declare @CreateJob tinyint
	set @CreateJob = 1
	
	Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')
	Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
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
		ID int IDENTITY (1, 1) NOT NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Could not create temporary table'
		RAISERROR (@message, 10, 1)
		return @myError
	End
	
	---------------------------------------------------
	-- Populate the job holding table (#JX)
	---------------------------------------------------
	declare @result int

	exec @result = EvaluatePredefinedAnalysisRules @datasetNum, 'Export Jobs', @message output, @RaiseErrorMessages=0, @ExcludeDatasetsNotReleased=@ExcludeDatasetsNotReleased
	--
	If @result <> 0
	Begin
		Set @ErrorMessage = 'EvaluatePredefinedAnalysisRules returned error code ' + Convert(varchar(12), @result)
	
		If Not IsNull(@message, '') = ''
			Set @ErrorMessage = @ErrorMessage + '; ' + @message
		
		Set @message = @ErrorMessage
		
		RAISERROR (@message, 10, 1)
		return 53500
	End

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
	declare @proteinCollectionList varchar(4000)
	declare @proteinOptionsList varchar(256)
	declare @comment varchar(128)
	declare @ID int

	declare @jobNum varchar(32)
	declare @ownerPRN varchar(32)
	
	declare @associatedProcessorGroup varchar(64)
	Set @associatedProcessorGroup = ''

	-- keep track of how many jobs have been scheduled
	--
	declare @jobsCreated int
	Set @jobsCreated = 0
	
	declare @done tinyint
	Set @done = 0
	
	declare @currID int
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
			@ID = ID
		FROM #JX
		WHERE ID > @currID
		ORDER BY ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- remember index and evaluate terminating conditions
		---------------------------------------------------
		Set @currID = @ID
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

			If @CreateJob <> 0
			Begin -- <c>
			
				If @InfoOnly <> 0
				Begin
					Print 'Call AddUpdateAnalysisJob for dataset ' + @datasetNum + ' and tool ' + @analysisToolName + '; param file: ' + IsNull(@parmFileName, '') + '; settings file: ' + IsNull(@settingsFileName, '')
				End
				Else
				Begin -- <d>
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
								@message output,
								@callingUser

					-- If there was an error creating the job, remember it
					-- otherwise bump the job count
					--
					If @result = 0 
						Set @jobsCreated = @jobsCreated + 1 
					Else 
						Set @myError = @result
				End -- </d>
			End -- </c>
		End -- </b>
		
		---------------------------------------------------
		-- If there was an error, log it
		---------------------------------------------------
		--
		If @myError <> 0 
		Begin
			Set @message = 'Attempted and failed to create default analysis for "' + @datasetNum + '" [' + convert(varchar(12), @myError) + ']'
			execute PostLogEntry 'Error', @message, 'ScheduleDefaultAnalyses'
		End
	End -- </b>
	
	---------------------------------------------------
	-- If we didn't schedule any jobs, 
	-- but didn't have any errors, return code of 1
	---------------------------------------------------
	--
	If @InfoOnly = 0 And @myError = 0 And @jobsCreated = 0 
		Set @myError = 1

Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[SchedulePredefinedAnalyses] TO [DMS_Analysis] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SchedulePredefinedAnalyses] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SchedulePredefinedAnalyses] TO [PNL\D3M580] AS [dbo]
GO
