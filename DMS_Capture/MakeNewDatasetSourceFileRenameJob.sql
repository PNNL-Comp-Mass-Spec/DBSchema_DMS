/****** Object:  StoredProcedure [dbo].[MakeNewDatasetSourceFileRenameJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeNewDatasetSourceFileRenameJob
/****************************************************
**
**	Desc: 
**    Creates a new dataset source file rename job for the specified dataset
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/06/2012 mem - Initial version
**    
*****************************************************/
(
	@DatasetName varchar(128),
	@infoOnly tinyint = 0,							-- 0 To perform the update, 1 preview job that would be created
	@message varchar(512)='' output
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @DatasetID int
	Declare @JobID int

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	
	If @DatasetName Is Null
	Begin
		Set @message = 'Dataset name not defined'
		Set @myError = 50000
		Goto Done
	End

	---------------------------------------------------
	-- Validate this dataset and determine its Dataset_ID
	---------------------------------------------------
	
	Set @DatasetID = 0
	
	SELECT @DatasetID = Dataset_ID
	FROM V_DMS_Get_Dataset_Info
	WHERE Dataset_num = @DatasetName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0
	Begin
		Set @message = 'Dataset not found: ' + @DatasetName + '; unable to continue'
		Set @myError = 50002
		Goto Done
	End

	---------------------------------------------------
	-- Make sure a pending source file rename job doesn't already exist
	---------------------------------------------------
	--
	Set @JobID = 0
	
	SELECT @JobID = Job
	FROM T_Jobs
	WHERE (Script = 'SourceFileRename') AND
	      (T_Jobs.Dataset_ID = @DatasetID) AND
	      (State < 3)

	If @JobID > 0 
	Begin
		Set @message = 'Existing pending job already exists for ' + @DatasetName + '; job ' + Convert(varchar(12), @JobID)
		Set @myError = 0
		Goto Done
	End

	
	---------------------------------------------------
	-- create new SourceFileRename job for specified dataset
	---------------------------------------------------
	--
	If @infoOnly <> 0
	Begin
		SELECT
			'SourceFileRename' AS Script,
			@DatasetName AS Dataset,
			@DatasetID AS Dataset_ID,
			'Manually created using MakeNewArchiveUpdateJob' AS Comment
	End
	Else
	Begin
	
		INSERT INTO T_Jobs (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
		SELECT
			'SourceFileRename' AS Script,
			@DatasetName AS Dataset,
			@DatasetID AS Dataset_ID,
			NULL AS Results_Folder_Name,
			'Created manually using MakeNewDatasetSourceFileRenameJob' AS Comment
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to add new Source File Rename step'
			goto Done
		end	
		
		Set @JobID = SCOPE_IDENTITY()
		
		Set @message = 'Created Job ' + Convert(varchar(12), @JobID) + ' for dataset ' + @DatasetName
		
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	
	If @message <> ''
		Print @message

GO
