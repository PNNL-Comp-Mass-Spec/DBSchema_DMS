/****** Object:  StoredProcedure [dbo].[CloneDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure CloneDataset
/****************************************************
**
**	Desc: 
**		Clones a dataset, including creating a new requested run, new experiment (if necessary), and new analysis jobs
**
**	Return values: 0 if no error; otherwise error code
**
**	Auth:	mem
**	Date:	02/23/2012
**    
*****************************************************/
(
	@infoOnly tinyint = 1,						-- Change to 0 to actually perform the clone; 1 to preview items that would be created
	@Dataset varchar(128),						-- Dataset name to clone
	@Suffix varchar(24) = '_C01',				-- Suffix to apply to cloned dataset, experiment, and requested run
	@message varchar(255) = '' OUTPUT
)
AS
	set nocount on

	declare @myRowCount int	
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Declare @TranClone varchar(24) = 'Clone'
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @Dataset = IsNull(@Dataset, '')
	Set @Suffix = IsNull(@Suffix, '')
	
	Set @message = ''
	
	If @Dataset = ''
	Begin
		Set @message = '@Dataset parameter cannot be empty'
		print @message
		Goto Done
	End

	If @Suffix = ''
	Begin
		Set @message = '@Suffix parameter cannot be empty'
		print @message
		Goto Done
	End
	
	---------------------------------------------------
	-- Make sure the target dataset does not already exist
	---------------------------------------------------
	
	Declare @DatasetNew varchar(128) = @Dataset + @Suffix
	
	If Exists (SELECT * FROM T_Dataset WHERE Dataset_Num = @DatasetNew)
	Begin
		Set @message = 'Target dataset already exists: ' + @DatasetNew
		print @message
		Goto Done
	End
	
	
	---------------------------------------------------
	-- Create temporary tables
	---------------------------------------------------

	CREATE TABLE #Tmp_JobsToClone (
		Job int not null,
		JobNew int null
	)

	CREATE CLUSTERED INDEX #IX_Tmp_JobsToClone ON #Tmp_JobsToClone (Job)
	
	
	---------------------------------------------------
	-- Find Experiments to delete
	---------------------------------------------------
	
	
	
	--
	Select @myRowCount = @@RowCount, @myError = @@Error


		BEGIN TRY 

			Begin Tran @TranClone
		
			set @message = 'Do Work'
			
			Commit
		
		
			-- Exec PostLogEntry 'Normal', @message, 'CloneDataset'
			
			
		END TRY
		BEGIN CATCH 
			-- Error caught
			If @@TranCount > 0
				Rollback
			
			Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'CloneDataset')
					exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0, 
											@ErrorNum = @myError output, @message = @message output
											
			Set @message = 'Exception: ' + @message
			print @message
			Goto Done
		END CATCH
	
	
Done:

	Return @myError

GO
