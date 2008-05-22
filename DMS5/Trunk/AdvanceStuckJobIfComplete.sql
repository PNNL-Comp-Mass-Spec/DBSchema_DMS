/****** Object:  StoredProcedure [dbo].[AdvanceStuckJobIfComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AdvanceStuckJobIfComplete
/****************************************************
**
**	Desc:	Looks for the results folder for the given job
**			If found, and if the folder contains the required file(s), then calls
**			 SetAnalysisJobComplete or SetDataExtractionTaskComplete (depending on the current job state)
**
**			Use @infoOnly = 1 to preview updates
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	04/29/2008 (Ticket:672)
**    
*****************************************************/
(
	@Job int,
	@JobCompleteHoldoffMinutes int = 60,
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0,
	@PreviewSql tinyint = 0
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @JobText varchar(64)
	Declare @JobState int
	Declare @JobStart datetime
	Declare @Processor varchar(128)
	Declare @Dataset varchar(256)
	Declare @Comment varchar(512)

	declare @AnalysisManagerIsDone tinyint
	declare @DataExtractionIsDone tinyint
	declare @ResultsFolderName varchar(128)
	declare @ResultsFolderPath varchar(512)
	declare @ResultsFolderTimestamp datetime
	declare @OrganismDBName varchar(128)

	Declare @Sql varchar(2048)

	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	If @Job Is Null
	Begin
		Set @Message = '@Job is null; unable to continue'
		Set @myError = 50000
		Goto Done
	End
	Else
		Set @JobText = 'Job ' + Convert(varchar(19), @Job)
	
	Set @JobCompleteHoldoffMinutes = IsNull(@JobCompleteHoldoffMinutes, 60)
	If @JobCompleteHoldoffMinutes < 10
		Set @JobCompleteHoldoffMinutes = 10

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @PreviewSql = IsNull(@PreviewSql, 0)

	------------------------------------------------
	-- Confirm that the job is in the correct state
	------------------------------------------------

	Set @JobState = 0
	SELECT	@JobState = AJ.AJ_StateID,
			@JobStart = AJ.AJ_start,
			@Processor = AJ.AJ_assignedProcessorName,
			@Comment = AJ.AJ_Comment,
			@Dataset = DS.Dataset_Num
	FROM dbo.T_Analysis_Job AJ
		INNER JOIN dbo.T_Dataset DS
		 ON AJ.AJ_datasetID = DS.Dataset_ID
		INNER JOIN dbo.t_storage_path SPath
		 ON DS.DS_storage_path_ID = SPath.SP_path_ID
	WHERE AJ.AJ_jobID = @Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		Set @message = @JobText + ' not found in T_Analysis_Job; unable to continue'
		Set @myError = 50001
		Goto Done
	End
	
	If Not IsNull(@JobState, 0) In (2, 17)
	Begin
		Set @message = @JobText + ' does not have a state of "Job In Progress" or "Data Extraction In Progress"; unable to continue'
		Set @myError = 50002
		Goto Done
	End


	------------------------------------------------
	-- Call CLR Assembly function ValidateAnalysisJobResultsFolder to look for the results folder for this job
	------------------------------------------------
	
	-- Note, the ValidateAnalysisJobResultsFolder Assembly must have EXTERNAL_ACCESS permission
	-- Grant the permission using:
	--     ALTER ASSEMBLY AnalysisJobResultFolderValidation]
	--     WITH PERMISSION_SET = EXTERNAL_ACCESS

	exec d3l243.ValidateAnalysisJobResultsFolder 
		@job, 
		@JobCompleteHoldoffMinutes, 
		@AnalysisManagerIsDone output, 
		@DataExtractionIsDone output,
		@ResultsFolderName output,
		@ResultsFolderPath output,
		@ResultsFolderTimestamp output,
		@OrganismDBName output,
		@Message output,
		@infoOnly = @infoOnly

	If @infoOnly <> 0
		select	@AnalysisManagerIsDone AS AnalysisManagerIsDone, 
				@DataExtractionIsDone AS DataExtractionIsDone,  
				@ResultsFolderName AS ResultsFolderName, 
				@ResultsFolderPath AS ResultsFolderPath, 
				@ResultsFolderTimestamp AS ResultsFolderTimestamp, 
				@OrganismDBName AS OrganismDBName, 
				@Message AS Message

	if @AnalysisManagerIsDone <> 0
	Begin
		If @JobState = 2
		Begin
			-- Call SetAnalysisJobComplete

			If Len(IsNull(@OrganismDBName, '')) = 0
				Set @OrganismDBName = 'na'

			Set @Sql = 'Exec SetAnalysisJobComplete ' + Convert(varchar(19), @Job) + ', ''' + @Processor + ''', 0, ''' + @ResultsFolderName + ''', ''' + @Comment + ''', ''' + @OrganismDBName + ''''
			If IsNull(@InfoOnly,-1) = 0
				Exec (@Sql)
			Else
				Print @Sql
		End

		If @JobState = 17
		Begin
			-- Call SetDataExtractionTaskComplete

			Set @Sql = 'Exec SetDataExtractionTaskComplete ' + Convert(varchar(19), @Job) + ', 0, ''' + @Comment + ''''
			If IsNull(@InfoOnly,-1) = 0
				Exec (@Sql)
			Else
				Print @Sql
		End
	End
	
Done:

	If @infoOnly <> 0
		Print @message

	return @myError

GO
GRANT ALTER ON [dbo].[AdvanceStuckJobIfComplete] TO [D3L243]
GO
GRANT EXECUTE ON [dbo].[AdvanceStuckJobIfComplete] TO [D3L243]
GO
