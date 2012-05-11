/****** Object:  StoredProcedure [dbo].[UpdateInputFolderUsingSpecialProcessingParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE UpdateInputFolderUsingSpecialProcessingParam
/****************************************************
**
**	Desc:	Updates the input folder name using the SourceJob:0000 tag defined for the specified jobs
**			Only affects job steps that have Special="ExtractSourceJobFromComment"
**			defined in the job script
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/21/2011 mem - Initial Version
**			03/22/2011 mem - Now calling AddUpdateJobParameter to store the SourceJob in T_Job_Parameters
**			04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**    
*****************************************************/
(
	@JobList varchar(max),
	@infoOnly tinyint = 0,
	@ShowResults tinyint = 2,				-- 0 to not show results, 1 to show results if #Tmp_Source_Job_Folders is populated; 2 to show results even if #Tmp_Source_Job_Folders is not populated
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @EntryID int
	Declare @Job int
	
	Declare @scriptXML xml
	Declare @Script varchar(255)
	Declare @ActionText varchar(128)

	Declare @SourceJob int
	Declare @SourceJobText varchar(12)
	
	CREATE TABLE #Tmp_JobList (
		Job int NOT NULL,
		Script varchar(128) NOT NULL,
		Message varchar(512) NULL
	)
	
	CREATE TABLE #Tmp_Source_Job_Folders (
		Entry_ID int identity(1,1),
		Job int NOT NULL,
		Step int NOT NULL,
		SourceJob int NULL,
		SourceJobResultsFolder varchar(255) NULL,
		WarningMessage varchar(1024) NULL
	)

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @ShowResults = IsNull(@ShowResults, 2)
	Set @message = IsNull(@message, '')


	---------------------------------------------------
	-- Parse the jobs in @JobList
	---------------------------------------------------
	--
	INSERT INTO #Tmp_JobList (Job, Script, Message)
	SELECT Value AS Job,
	       IsNull(J.Script, '') AS Script,
	       CASE WHEN J.Job IS NULL THEN 'Job Number not found in T_Jobs' ELSE '' END
	FROM dbo.udfParseDelimitedIntegerList ( @JobList, ',' ) JL
	     LEFT OUTER JOIN T_Jobs J
	       ON JL.VALUE = J.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	
	---------------------------------------------------
	-- Step through the jobs in #Tmp_JobList
	-- and populate #Tmp_Source_Job_Folders
	---------------------------------------------------
	
	Declare @continue tinyint
	Set @continue = 1
	Set @Job = 0
	
	While @Continue = 1 And @myError = 0
	Begin -- <a1>
		SELECT TOP 1 @Job = Job,
		             @Script = Script
		FROM #Tmp_JobList
		WHERE Job > @Job And Script <> ''
		ORDER BY Job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		IF @myRowCount = 0
			Set @Continue = 0
		Else
		Begin -- <b1>
			Set @scriptXML = ''
			
			-- Lookup the XML for the specified script
			--		
			SELECT @scriptXML = Contents
			FROM T_scripts
			WHERE Script = @Script
	
			-- Add new rows to #Tmp_Source_Job_Folders for any steps in the script
			-- that have Special_Instructions = 'ExtractSourceJobFromComment'
			--
			INSERT INTO #Tmp_Source_Job_Folders (Job, Step)
			SELECT @Job, Step_Number
			FROM (
				SELECT
					xmlNode.value('@Number', 'nvarchar(128)') Step_Number,
					xmlNode.value('@Tool', 'nvarchar(128)') Step_Tool,
					xmlNode.value('@Special', 'nvarchar(128)') Special_Instructions
				FROM
					@scriptXML.nodes('//Step') AS R(xmlNode)
					) LookupQ
			WHERE Special_Instructions = 'ExtractSourceJobFromComment'
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
			Begin
				-- Record a warning since no valid steps were found
				--
				UPDATE #Tmp_JobList
				SET Message = 'Script does not contain a step with Special_Instructions=''ExtractSourceJobFromComment'''
				WHERE Job = @Job
			End
			
		End -- </b1>		
	End -- </a1>
	
	IF EXISTS (SELECT * FROM #Tmp_Source_Job_Folders)
	Begin -- <a2>
		-- Lookup the SourceJob info for each job in #Tmp_Source_Job_Folders
		-- This procedure examines the Special_Processing parameter for each job (in T_Job_Parameters)
		exec LookupSourceJobFromSpecialProcessingParam @message=@message output, @PreviewSql=@infoOnly
		
		If @infoOnly = 0
		Begin -- <b2>
			-- Apply the changes
			UPDATE T_Job_Steps
			SET Input_Folder_Name = SJF.SourceJobResultsFolder
			FROM T_Job_Steps JS
			     INNER JOIN #Tmp_Source_Job_Folders SJF
			       ON JS.Job = SJF.Job AND
			          JS.Step_Number = SJF.Step
			WHERE IsNull(SJF.SourceJobResultsFolder, '') <> ''
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			
			-- Update the parameters for each job in #Tmp_Source_Job_Folders
			Set @Job = 0
			Set @Continue = 1
	
			While @Continue = 1 And @myError = 0
			Begin -- <c>
				SELECT TOP 1 @Job = Job,
				             @SourceJob = SourceJob
				FROM #Tmp_Source_Job_Folders
				WHERE Job > @Job AND
				      NOT SourceJob IS NULL
				ORDER BY Job, Step
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				IF @myRowCount = 0
					Set @Continue = 0
				Else
				Begin -- <d>
					Set @SourceJobText = Convert(varchar(12), @SourceJob)
					
					Exec AddUpdateJobParameter @Job, 'JobParameters', 'SourceJob', @SourceJobText, @DeleteParam=0, @infoOnly=0
					
				End -- </d>
			End -- </c>
			
		End -- </b2>

		If @infoOnly = 0
			Set @ActionText = 'Updated input folder to '
		Else
			Set @ActionText = 'Preview update of input folder to '
			
		-- Update the message field in #Tmp_JobList
		UPDATE #Tmp_JobList
		Set Message = @ActionText + SJF.SourceJobResultsFolder
		FROM #Tmp_JobList JL
		     INNER JOIN #Tmp_Source_Job_Folders SJF
		       ON JL.Job = SJF.Job
		WHERE IsNull(SJF.SourceJobResultsFolder, '') <> ''
		
		
		If @ShowResults <> 0
		Begin
			SELECT JL.*,
				SJF.Step,
				SJF.SourceJob,
				SJF.SourceJobResultsFolder,
				SJF.WarningMessage
			FROM #Tmp_JobList JL
				LEFT OUTER JOIN #Tmp_Source_Job_Folders SJF
				ON JL.Job = SJF.Job
			ORDER BY Job
		End
		
	End -- </a2>
	Else
	Begin -- <a3>
		If @ShowResults = 2
		Begin
			-- Nothing to do; simply display the contents of #Tmp_JobList
			SELECT *
			FROM #Tmp_JobList
			ORDER BY Job
		End
	End -- </a3>
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
