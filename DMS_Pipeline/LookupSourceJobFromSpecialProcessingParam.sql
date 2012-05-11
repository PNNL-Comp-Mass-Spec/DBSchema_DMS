/****** Object:  StoredProcedure [dbo].[LookupSourceJobFromSpecialProcessingParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE LookupSourceJobFromSpecialProcessingParam
/****************************************************
**
**	Desc:	Looks up the source job defined for a new job
**			The calling procedure must create temporary table #Tmp_Source_Job_Folders
**
**		CREATE TABLE #Tmp_Source_Job_Folders (
**				Entry_ID int identity(1,1),
**				Job int NOT NULL,
**				Step int NOT NULL,
**				SourceJob int NULL,
**				SourceJobResultsFolder varchar(255) NULL,
**				WarningMessage varchar(1024) NULL
**			)
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/21/2011 mem - Initial Version
**			04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**			04/20/2011 mem - Updated to support cases where @SpecialProcessingText contains ORDER BY
**			05/03/2012 mem - Now calling LookupSourceJobFromSpecialProcessingText to parse @SpecialProcessingText
**			05/04/2012 mem - Now passing @TagName and @AutoQueryUsed to LookupSourceJobFromSpecialProcessingText
**    
*****************************************************/
(
	@message varchar(512)='' output,
	@PreviewSql tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @EntryID int
	Declare @Job int
	
	Declare @Dataset varchar(255)
	Declare @SpecialProcessingText varchar(1024)
	
	Declare @SourceJob int
	Declare @AutoQueryUsed tinyint
	Declare @SourceJobResultsFolder varchar(255)
	
	Declare @WarningMessage varchar(1024)
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Set @message = IsNull(@message, '')
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	
	---------------------------------------------------
	-- Step through each entry in #Tmp_Source_Job_Folders
	---------------------------------------------------
	
	Declare @continue tinyint
	Set @continue = 1
	Set @EntryID = 0
	Set @Job = 0
	
	While @Continue = 1 And @myError = 0
	Begin -- <a>
		SELECT TOP 1 @EntryID = Entry_ID,
		             @Job = Job
		FROM #Tmp_Source_Job_Folders
		WHERE Entry_ID > @EntryID
		ORDER BY Entry_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		IF @myRowCount = 0
			Set @Continue = 0
		Else
		Begin -- <b>
		
			Begin Try
			
				Set @CurrentLocation = 'Determining SourceJob for job ' + Convert(varchar(12), @Job)
			
				Set @Dataset = ''
				Set @SpecialProcessingText = ''
				Set @SourceJob = 0
				Set @SourceJobResultsFolder = 'UnknownFolder_Invalid_SourceJob'
				Set @WarningMessage = ''				
				
				-- Lookup the Dataset for this job
				--		
				SELECT @Dataset = Dataset
				FROM T_Jobs
				WHERE Job = @Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
					Set @WarningMessage = 'Job ' + Convert(varchar(12), @Job) +  ' not found in T_Jobs'
				Else
				Begin
					
					-- Lookup the Special_Processing parameter for this job
					--
					SELECT @SpecialProcessingText = Value
					FROM dbo.GetJobParamTableLocal(@Job)
					WHERE [Name] = 'Special_Processing'
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					
					If @myRowCount = 0
					Begin
						Set @WarningMessage = 'Job ' + Convert(varchar(12), @Job) + ' does not have a Special_Processing entry in T_Job_Parameters'
					End
					
					If @WarningMessage = ''
					Begin
						If Not @SpecialProcessingText LIKE '%SourceJob:%'
						Begin
							Set @WarningMessage = 'Special_Processing parameter for job ' + Convert(varchar(12), @Job) + ' does not contain tag "SourceJob:0000" Or "SourceJob:Auto{Sql_Where_Clause}"'
							execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingParam'
						End
					End
				End
								
				If @WarningMessage = ''
				Begin
					Declare	@TagName varchar(12) = 'SourceJob'
					
					Exec @myError = LookupSourceJobFromSpecialProcessingText 
											  @Job,
					                          @Dataset, 
					                          @SpecialProcessingText, 
					                          @TagName,
					                          @SourceJob=@SourceJob output, 
					                          @AutoQueryUsed=@AutoQueryUsed output,
					                          @WarningMessage=@WarningMessage output, 
					                          @PreviewSql = @PreviewSql
					
					If IsNull(@WarningMessage, '') <> ''
					Begin
						execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingParam'
						
						If @WarningMessage Like '%exception%'
							Set @SourceJobResultsFolder = 'UnknownFolder_Exception_Determining_SourceJob'
						Else
						Begin
							If @AutoQueryUsed <> 0
								Set @SourceJobResultsFolder = 'UnknownFolder_AutoQuery_SourceJob_NoResults'						
						End						
					End
					
				End
		
				If @WarningMessage = ''
				Begin
					
					-- Lookup the results folder for the source job
					SELECT @SourceJobResultsFolder = IsNull([Results Folder], '')
					FROM S_DMS_V_Analysis_Job_Info
					WHERE Job = @SourceJob
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
				
					If @myRowCount = 0
						Set @WarningMessage = 'Source Job ' + Convert(varchar(12), @Job) +  'not found in DMS'
				End
		
				-- Store the results
				--
				UPDATE #Tmp_Source_Job_Folders
				SET SourceJob = @SourceJob,
					SourceJobResultsFolder = @SourceJobResultsFolder,
					WarningMessage = @WarningMessage
				WHERE Entry_ID = @EntryID
	
			End Try
			Begin Catch
				-- Error caught; log the error, then continue with the next job
				Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'LookupSourceJobFromSpecialProcessingParam')
					
				exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
										@ErrorNum = @myError output, @message = @message output

				Set @SourceJobResultsFolder = 'UnknownFolder_Exception_Determining_SourceJob'
				If @WarningMessage = ''
					Set @WarningMessage = 'Exception while determining SourceJob and/or results folder'
					
				UPDATE #Tmp_Source_Job_Folders
				SET SourceJob = @SourceJob,
					SourceJobResultsFolder = @SourceJobResultsFolder,
					WarningMessage = @WarningMessage
				WHERE Entry_ID = @EntryID
				
			End Catch
							
		End -- </b>
		
	End -- </a>
 
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError


GO
