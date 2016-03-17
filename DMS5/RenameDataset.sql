/****** Object:  StoredProcedure [dbo].[RenameDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RenameDataset
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

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @DatasetID int = 0
	Declare @JobsToUpdate table (Job int not null)
	Declare @Job int = 0
	Declare @Continue tinyint

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


	If @InfoOnly = 0 
	Begin
		--------------------------------------------
		-- Rename the dataset in T_Dataset
		--------------------------------------------
		--
		If Not Exists (Select * from T_Dataset WHERE Dataset_Num = @DatasetNameNew)
		Begin
			UPDATE T_Dataset
			SET Dataset_Num = @DatasetNameNew,
			    DS_folder_name = @DatasetNameNew
			WHERE Dataset_Num = @DatasetNameOld
			
			Set @message = 'Renamed dataset "' + @DatasetNameOld + '" to "' + @DatasetNameNew + '"'
			print @message
				
			Exec PostLogEntry 'Normal', @message, 'RenameDataset'
		End
	End
	Else
	Begin
		-- Preview the dataset
		
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
	-- Update jobs in the DMS_Capture database
	--------------------------------------------
	--
	DELETE FROM @JobsToUpdate
	
	INSERT INTO @JobsToUpdate (Job)
	SELECT Job 
	FROM DMS_Capture.dbo.T_Jobs 
	WHERE dataset = @DatasetNameOld
	ORDER BY Job
	
	If @InfoOnly = 0
	Begin
		Set @Continue = 1
		Set @Job = 0
	End
	Else
	Begin
		Set @Continue = 0
		SELECT Job AS Capture_Job, Script, State, Dataset, @DatasetNameNew as Dataset_Name_New, Dataset_ID, Imported
		FROM DMS_Capture.dbo.T_Jobs 
		WHERE Job In (Select Job from @JobsToUpdate)
	End
		
	While @Continue = 1
	Begin
		SELECT TOP 1 @Job = Job
		FROM @JobsToUpdate
		WHERE Job > @Job
		ORDER BY Job		
		
		If @@RowCount = 0
			Set @Continue = 0
		Else
		Begin
		
			exec DMS_Capture.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'Dataset', @DatasetNameNew, @infoonly=0
			exec DMS_Capture.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'Folder',  @DatasetNameNew, @infoonly=0
			
			UPDATE DMS_Capture.dbo.T_Jobs 
			Set Dataset = @DatasetNameNew
			WHERE Job = @Job			
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

	If @InfoOnly = 0
	Begin
		Set @Continue = 1
		Set @Job = 0
	End
	Else
	Begin
		Set @Continue = 0
		SELECT Job AS Pipeline_Job, Script, State, Dataset, @DatasetNameNew as Dataset_Name_New, Dataset_ID, Imported
		FROM DMS_Pipeline.dbo.T_Jobs 
		WHERE Job In (Select Job from @JobsToUpdate)
	End
	
	While @Continue = 1
	Begin
		SELECT TOP 1 @Job = Job
		FROM @JobsToUpdate
		WHERE Job > @Job
		ORDER BY Job		
		
		If @@RowCount = 0
			Set @Continue = 0
		Else
		Begin
		
			exec DMS_Pipeline.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'DatasetNum',        @DatasetNameNew, @infoonly=0
			exec DMS_Pipeline.dbo.AddUpdateJobParameter @Job, 'JobParameters', 'DatasetFolderName', @DatasetNameNew, @infoonly=0
			
			UPDATE DMS_Pipeline.dbo.T_Jobs 
			Set Dataset = @DatasetNameNew
			WHERE Job = @Job			
		End

	End
			
 	---------------------------------------------------
	-- Done
 	---------------------------------------------------
Done:

	If @message <> ''
		print @message
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RenameDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RenameDataset] TO [PNL\D3M580] AS [dbo]
GO
