/****** Object:  StoredProcedure [dbo].[DuplicateAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DuplicateAnalysisJob
/****************************************************
**
**	Desc: Duplicates an analysis job by alling AddUpdateAnalysisJob
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	01/20/2016 mem - Initial version
**			01/28/2016 mem - Added parameter @newSettingsFile
**    
*****************************************************/
(
	@job int,								-- Job number to copy
	@newComment varchar(512) = '',			-- New job comment; use old comment if blank
	@overrideNoExport smallint = -1,		-- 0 for export, 1 for No Export, -1 to leave unchanged
	@appendOldJobToComment tinyint = 1,		-- If 1 append "Compare to job 0000" to the comment
	@newSettingsFile varchar(255) = '',		-- Use to change the settings file
	@infoOnly tinyint = 0,					-- 0 to create the job, 1 to preview
	@message varchar(512) = '' output		-- Output message
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @job = IsNull(@job, 0)
	Set @newComment = IsNull(@newComment, '')
	Set @overrideNoExport = IsNull(@overrideNoExport, -1)
	Set @appendOldJobToComment = IsNull(@appendOldJobToComment, 1)
	Set @newSettingsFile = IsNull(@newSettingsFile, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	
	If @job = 0
	Begin
		Set @message = '@job is invalid'
		Select @message as Error
		
		Goto Done
	End


    Declare @dataset varchar(128)
    Declare @priority int
	Declare @toolName varchar(64)
    Declare @parmFileName varchar(255)
    Declare @settingsFileName varchar(255)
    Declare @organismName varchar(128)
    Declare @protCollNameList varchar(4000)
    Declare @protCollOptionsList varchar(256)
	Declare @organismDBName varchar(128)
    Declare @ownerPRN varchar(64)
    Declare @comment varchar(512)
    Declare @specialProcessing varchar(512)
    Declare @propMode smallint
    
	---------------------------------------------------
	-- Lookup the job values in T_Analysis_Job
	---------------------------------------------------
	--
	SELECT @dataset = DS.Dataset_Num,
	       @priority = J.AJ_priority,
	       @toolName = T_Analysis_Tool.AJT_toolName,
	       @parmFileName = J.AJ_parmFileName,
	       @settingsFileName = J.AJ_settingsFileName,
	       @organismName = Org.OG_name,
	       @protCollNameList = J.AJ_proteinCollectionList,
	       @protCollOptionsList = J.AJ_proteinOptionsList,
	       @organismDBName = J.AJ_organismDBName,
	       @ownerPRN = J.AJ_owner,
	       @comment = J.AJ_comment,
	       @specialProcessing = J.AJ_specialProcessing,
	       @propMode = J.AJ_propagationMode
	FROM T_Analysis_Job J
	     INNER JOIN T_Organisms Org
	       ON J.AJ_organismID = Org.Organism_ID
	     INNER JOIN T_Dataset DS
	       ON J.AJ_datasetID = DS.Dataset_ID
	     INNER JOIN T_Analysis_Tool
	       ON J.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
	WHERE J.AJ_jobID = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @message = 'Job not found: ' + Cast(@job as varchar(11))
		Select @message as Error
		
		Goto Done
	End
	
	If @newComment <> ''
		Set @comment = @newComment
	
	If @appendOldJobToComment <> 0
	Begin
		Declare @oldJobInfo varchar(24) = 'Compare to job ' + Cast(@job as varchar(12))
		Set @comment = dbo.AppendToText(@comment, @oldJobInfo, 0, '; ')
	End

	If @newSettingsFile <> ''
		Set @settingsFileName = @newSettingsFile

    Declare @propagationMode varchar(24)
	
	If @overrideNoExport >= 0
		Set @propMode = @overrideNoExport
		
	If @propMode <> 0
		Set @propagationMode = 'No Export'
	Else
		Set @propagationMode = 'Export'

	If @infoOnly <> 0
	Begin
		SELECT @dataset AS dataset,
		       @priority AS priority,
		       @toolName AS toolName,
		       @parmFileName AS parmFileName,
		       @settingsFileName AS settingsFileName,
		       @organismName AS organismName,
		       @protCollNameList AS protCollNameList,
		       @protCollOptionsList AS protCollOptionsList,
		       @organismDBName AS organismDBName,
		       @ownerPRN AS ownerPRN,
		       @comment AS [Comment],
		       @specialProcessing AS specialProcessing,
		       @propagationMode as Propagation_Mode
	End

	Declare @newJob varchar(32)
	
	-- Call the stored procedure to create/preview the job creation
	EXEC @myError = AddUpdateAnalysisjob
		@dataset,
		@priority,
		@toolName,
		@parmFileName,
		@settingsFileName,
		@organismName,
		@protCollNameList,
		@protCollOptionsList,
		@organismDBName,
		@ownerPRN,
		@comment,
		@specialProcessing,
		@propagationMode      = @propagationMode,
		@stateName            = 'New',
		@mode                 = 'add',
		@message              = @message OUTPUT,
		@PreventDuplicateJobs = 0,
		@infoOnly             = @infoOnly,
		@jobNum = @newJob OUTPUT

	If @infoonly = 0
	Begin
		If @myError = 0
		Begin
			Set @message = 'Duplicated job ' + Cast(@job as varchar(12)) + ' to create job ' + IsNull(@newJob, '')
			Select @message as Result
		End
		Else
		Begin
			If IsNull(@message, '') = ''
				Set @message = 'AddUpdateAnalysisjob returned error code = ' + Cast(@myError as varchar(12))
			Select @message as Error
		End
		
		
	End
	
Done:
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
