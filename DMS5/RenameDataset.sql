/****** Object:  StoredProcedure [dbo].[RenameDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RenameDataset]
/****************************************************
**
**	Desc: 
**		Renames a dataset in T_Dataset
		Renames associated jobs in the DMS_Capture and DMS_Pipeline databases
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**			01/25/2013 mem - Initial version
**			07/08/2016 mem - Now show old/new names and jobs even when @infoOnly is 0
**			12/06/2016 mem - Include file rename statements
**			03/06/2017 mem - Validate that @DatasetNameNew is no more than 80 characters long
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@DatasetNameOld varchar(128) = '',
	@DatasetNameNew varchar(128) = '',
    @message varchar(512) = '' output,
	@infoOnly tinyint = 1
)
AS
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	Declare @DatasetID int = 0
	Declare @folderPath varchar(255) = ''

	Declare @JobsToUpdate table (Job int not null)
	Declare @Job int = 0
	
	Declare @suffixID int
	Declare @fileSuffix varchar(64)
	
	Declare @Continue tinyint
	Declare @Continue2 tinyint
	
	Declare @toolBaseName varchar(64)
	Declare @resultsFolder varchar(128)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'RenameDataset', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	--------------------------------------------
	-- Validate the inputs
	--------------------------------------------
	--
	Set @DatasetNameOld = ISNULL(@DatasetNameOld, '')
	Set @DatasetNameNew = ISNULL(@DatasetNameNew, '')

	If @DatasetNameOld = ''
	Begin
		Set @message = '@DatasetNameOld is empty; unable to continue'
		Goto Done
	End

	If @DatasetNameNew = ''
	Begin
		Set @message = '@DatasetNameNew is empty; unable to continue'
		Goto Done
	End

	If Len(@DatasetNameNew) > 80
	Begin
		Set @message = 'New dataset name cannot be more than 80 characters in length'
		Goto Done
	End
	
	--------------------------------------------
	-- Lookup the dataset ID
	--------------------------------------------
	--
	SELECT @DatasetID = Dataset_ID
	FROM dbo.T_Dataset
	WHERE Dataset_Num = @DatasetNameOld

	If IsNull(@DatasetID, 0) = 0
	Begin
		-- Old dataset name not found; perhaps it was already renamed in T_Dataset
		SELECT @DatasetID = Dataset_ID
		FROM dbo.T_Dataset
		WHERE Dataset_Num = @DatasetNameNew
	End
	Else
	Begin

		-- Old dataset name found; make sure the new name is not already in use
		If Exists (SELECT * FROM dbo.T_Dataset WHERE Dataset_Num = @DatasetNameNew)
		Begin
			Set @message = 'New dataset name already exists; unable to rename ' + @DatasetNameOld + ' to ' + @DatasetNameNew
			Goto Done
		End

	End

	If @DatasetID = 0
	Begin
		Set @message = 'Dataset not found using either the old name or the new name (' +  @DatasetNameOld + ' or ' + @DatasetNameNew + ')'
		Goto Done
	End
			
	-- Lookup the share folder for this dataset
	SELECT @folderPath = Dataset_Folder_Path
	FROM V_Dataset_Folder_Paths
	WHERE Dataset_ID = @DatasetID

	If @InfoOnly = 0 
	Begin
		--------------------------------------------
		-- Rename the dataset in T_Dataset
		--------------------------------------------
		--
		If Not Exists (Select * from T_Dataset WHERE Dataset_Num = @DatasetNameNew)
		Begin
			SELECT Dataset_Num AS DatasetNameOld,
			       @DatasetNameNew AS DatasetNameNew,
			       Dataset_ID,
			       DS_Created
			FROM T_Dataset
			WHERE Dataset_Num IN (@DatasetNameOld, @DatasetNameNew)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			UPDATE T_Dataset
			SET Dataset_Num = @DatasetNameNew,
			    DS_folder_name = @DatasetNameNew
			WHERE Dataset_ID = @DatasetID AND Dataset_Num = @DatasetNameOld
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			Set @message = 'Renamed dataset "' + @DatasetNameOld + '" to "' + @DatasetNameNew + '"'
			print @message
				
			Exec PostLogEntry 'Normal', @message, 'RenameDataset'
		End
	End
	Else
	Begin
		-- Preview the changes
		
		If Exists (Select * from T_Dataset WHERE Dataset_Num = @DatasetNameNew)
			SELECT @DatasetNameOld AS DatasetNameOld,
			       Dataset_Num AS DatasetNameNew,
			       Dataset_ID,
			       DS_Created
			FROM T_Dataset
			WHERE Dataset_Num IN (@DatasetNameOld, @DatasetNameNew)
		Else
			SELECT Dataset_Num AS DatasetNameOld,
			       @DatasetNameNew AS DatasetNameNew,
			       Dataset_ID,
			       DS_Created
			FROM T_Dataset
			WHERE Dataset_Num IN (@DatasetNameOld, @DatasetNameNew)
	End

	--------------------------------------------
	-- Show example commands for renaming a .raw file
	--------------------------------------------
	--
	Print 'Pushd ' + @folderPath
	Print 'Move ' + @DatasetNameOld + '.raw ' + @DatasetNameNew + '.raw'

	--------------------------------------------
	-- Update jobs in the DMS_Capture database
	--------------------------------------------
	--
	DELETE FROM @JobsToUpdate
	
	INSERT INTO @JobsToUpdate (Job)
	SELECT Job 
	FROM DMS_Capture.dbo.T_Jobs 
	WHERE dataset = @DatasetNameOld
	ORDER BY Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	SELECT Job AS Capture_Job, Script, State, Dataset, @DatasetNameNew as Dataset_Name_New, Dataset_ID, Imported
	FROM DMS_Capture.dbo.T_Jobs 
	WHERE Job In (Select Job from @JobsToUpdate)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @InfoOnly = 0 And Exists (Select * From @JobsToUpdate)
	Begin
		Set @Continue = 1
		Set @Job = 0
	End
	Else
	Begin
		Set @Continue = 0
	End

	--------------------------------------------
	-- Update analysis jobs in DMS_Capture if @InfoOnly is 0
	--------------------------------------------
	--
	While @Continue = 1
	Begin
		SELECT TOP 1 @Job = Job
		FROM @JobsToUpdate
		WHERE Job > @Job
		ORDER BY Job		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin
		
			exec DMS_Capture.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'Dataset', @DatasetNameNew, @infoonly=0
			exec DMS_Capture.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'Folder',  @DatasetNameNew, @infoonly=0
			
			UPDATE DMS_Capture.dbo.T_Jobs 
			Set Dataset = @DatasetNameNew
			WHERE Job = @Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End

	End
	
	--------------------------------------------
	-- Update jobs in the DMS_Pipeline database
	--------------------------------------------
	--
	DELETE FROM @JobsToUpdate
	
	INSERT INTO @JobsToUpdate (Job)
	SELECT Job 
	FROM DMS_Pipeline.dbo.T_Jobs 
	WHERE Dataset = @DatasetNameOld
	ORDER BY Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	SELECT Job AS Pipeline_Job, Script, State, Dataset, @DatasetNameNew as Dataset_Name_New, Dataset_ID, Imported
	FROM DMS_Pipeline.dbo.T_Jobs 
	WHERE Job In (Select Job from @JobsToUpdate)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @InfoOnly = 0 And Exists (Select * From @JobsToUpdate)
	Begin
		Set @Continue = 1
		Set @Job = 0
	End
	Else
	Begin
		Set @Continue = 0
	End
	
	While @Continue = 1
	Begin
		SELECT TOP 1 @Job = Job
		FROM @JobsToUpdate
		WHERE Job > @Job
		ORDER BY Job		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin
		
			exec DMS_Pipeline.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'DatasetNum',        @DatasetNameNew, @infoonly=0
			exec DMS_Pipeline.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'DatasetFolderName', @DatasetNameNew, @infoonly=0
			
			UPDATE DMS_Pipeline.dbo.T_Jobs 
			Set Dataset = @DatasetNameNew
			WHERE Job = @Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End
	End

	--------------------------------------------
	-- Show example commands for renaming the job files
	--------------------------------------------
	--
	CREATE TABLE #Tmp_Extensions (
		SuffixID int identity(1,1),
		FileSuffix varchar(64) NOT null
	)

	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Extensions_ID on #Tmp_Extensions(SuffixID)
	CREATE UNIQUE INDEX #IX_Tmp_Extensions_Suffix on #Tmp_Extensions(FileSuffix)	

	DELETE FROM @JobsToUpdate
	
	INSERT INTO @JobsToUpdate (Job)
	SELECT Job 
	FROM V_Analysis_Job_Export 
	WHERE Dataset = @DatasetNameOld
	ORDER BY Job
	
	Set @Continue = 1
	Set @Job = 0
	
	Declare @jobFileUpdateCount int = 0
	
	While @Continue > 0
	Begin
		SELECT TOP 1 @Job = Job
		FROM @JobsToUpdate
		WHERE Job > @Job
		ORDER BY Job		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		Truncate Table #Tmp_Extensions
		
		If @myRowCount = 0
		Begin
			--------------------------------------------
			-- Show example commands for renaming QC files
			--------------------------------------------
			--
			Set @Continue = 0
			Set @resultsFolder = 'QC'
			
			Insert Into #Tmp_Extensions (FileSuffix) Values 
				('_BPI_MS.png'),('_BPI_MSn.png'),
				('_HighAbu_LCMS.png'),('_HighAbu_LCMS_MSn.png'),
				('_LCMS.png'),('_LCMS_MSn.png'),
				('_TIC.png'),('_DatasetInfo.xml')
		End
		Else
		Begin
			SELECT @toolBaseName = Tool.AJT_toolBasename,
				    @resultsFolder = ResultsFolder
			FROM V_Analysis_Job_Export AJE
				    INNER JOIN T_Analysis_Tool Tool
				    ON AJE.AnalysisTool = Tool.AJT_toolName
			WHERE Job = @Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0
			Begin
				If @toolBaseName = 'Decon2LS'
				Begin
					Insert Into #Tmp_Extensions (FileSuffix) Values 
						('_isos.csv'), ('_scans.csv'),
						('_BPI_MS.png'), ('_HighAbu_LCMS.png'), ('_HighAbu_LCMS_zoom.png'),
						('_LCMS.png'), ('_LCMS_zoom.png'),
						('_TIC.png'), ('_log.txt')
				End
				
				If @toolBaseName = 'MASIC'
				Begin
					Insert Into #Tmp_Extensions (FileSuffix) Values 
						('_MS_scans.csv'), ('_MSMS_scans.csv'),('_MSMethod.txt'), 
						('_ScanStats.txt'), ('_ScanStatsConstant.txt'), ('_ScanStatsEx.txt'), 
						('_SICstats.txt'),('_DatasetInfo.xml'),('_SICs.zip')
				End

				If @toolBaseName Like 'MSGFPlus%'
				Begin
					Insert Into #Tmp_Extensions (FileSuffix) Values 
						('_msgfplus.mzid.gz'),('_msgfplus_fht.txt'), ('_msgfplus_fht_MSGF.txt'),
						('_msgfplus_PepToProtMap.txt'), ('_msgfplus_PepToProtMapMTS.txt'),
						('_msgfplus_syn.txt'), ('_msgfplus_syn_ModDetails.txt'),
						('_msgfplus_syn_ModSummary.txt'),('_msgfplus_syn_MSGF.txt'),
						('_msgfplus_syn_ProteinMods.txt'),('_msgfplus_syn_ResultToSeqMap.txt'),
						('_msgfplus_syn_SeqInfo.txt'),('_msgfplus_syn_SeqToProteinMap.txt'),
						('_ScanType.txt'),('_pepXML.zip')

				End
			End
		End
		
		Print ''
		Print 'cd ' + @resultsFolder
		
		If Exists (Select * From #Tmp_Extensions)
			Set @Continue2 = 1
		Else
			Set @Continue2 = 0
			
		Set @suffixID = 0
		Set @fileSuffix = ''
		
		While @Continue2 = 1
		Begin
			SELECT TOP 1 @suffixID = SuffixID,
					     @fileSuffix = FileSuffix
			FROM #Tmp_Extensions
			WHERE SuffixID > @suffixID
			ORDER BY SuffixID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
				Set @Continue2 = 0
			Else
			Begin
				Print 'Move ' + @DatasetNameOld + @fileSuffix + ' ' + @DatasetNameNew + @fileSuffix
				Set @jobFileUpdateCount = @jobFileUpdateCount + 1
			End

		End
		
		Print 'cd ..'
		
	End

	If @jobFileUpdateCount > 0
	Begin
		Select 'See the console output for ' + Cast(@jobFileUpdateCount as varchar(9)) + ' dataset/job file update commands' as Comment
	End
	
 	---------------------------------------------------
	-- Done
 	---------------------------------------------------
Done:

	If @message <> ''
	Begin
		Select @message as Message
	End
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RenameDataset] TO [DDL_Viewer] AS [dbo]
GO
