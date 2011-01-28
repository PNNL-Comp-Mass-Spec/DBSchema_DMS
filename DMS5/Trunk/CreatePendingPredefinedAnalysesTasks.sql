/****** Object:  StoredProcedure [dbo].[CreatePendingPredefinedAnalysesTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreatePendingPredefinedAnalysesTasks]
/****************************************************
** 
**	Desc:
**		Creates job for new entries in T_Predefined_Analysis_Scheduling_Queue
**
**		Should be called periodically by SQL Agent job 
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**	Date:	08/26/2010 grk - initial release
**			08/26/2010 mem - Added @MaxDatasetsToProcess and @InfoOnly
**						   - Now passing @PreventDuplicateJobs to CreatePredefinedAnalysesJobs
**    
*****************************************************/
(
	@MaxDatasetsToProcess int = 0,			-- Set to a positive number to limit the number of affected datasets
	@InfoOnly tinyint = 0
)
AS
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	declare @message varchar(max)
	Set @message = ''

 	declare @datasetNum varchar(128)
 	declare @datasetID INT
	declare @callingUser varchar(128)
	declare @AnalysisToolNameFilter varchar(128)
	declare @ExcludeDatasetsNotReleased tinyint
	declare @PreventDuplicateJobs tinyint

	declare @done TINYINT
	declare @currentItemID INT
	declare @DatasetsProcessed INT
	declare @JobsCreated int = 0

 	---------------------------------------------------
	-- Validate the inputs
 	---------------------------------------------------
 	
 	Set @MaxDatasetsToProcess = IsNull(@MaxDatasetsToProcess, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
 	---------------------------------------------------
 	-- Process "New" entries in T_Predefined_Analysis_Scheduling_Queue
 	---------------------------------------------------
 	
 	Set @done = 0
 	Set @currentItemID = 0
 	Set @DatasetsProcessed = 0
 	
	WHILE @done = 0
	Begin
		SET @datasetNum = ''

		SELECT TOP 1 @currentItemID = Item,
		             @datasetNum = Dataset_Num,
		             @callingUser = CallingUser,
		             @AnalysisToolNameFilter = AnalysisToolNameFilter,
		             @ExcludeDatasetsNotReleased = ExcludeDatasetsNotReleased,
		             @PreventDuplicateJobs = PreventDuplicateJobs
		FROM T_Predefined_Analysis_Scheduling_Queue
		WHERE State = 'New' AND
		      Item > @currentItemID
		ORDER BY Item ASC
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		If @myRowCount = 0
		Begin
			SET @done = 1
		End
		ELSE 
		Begin
			If @InfoOnly <> 0
			Begin
				PRINT 'Process Item ' + Convert(varchar(12), @currentItemID) + ': ' + @datasetNum
			End

			If IsNull(@datasetNum, '') = ''
			Begin
				-- Dataset not defined; skip this entry
				Set @myError = 50
				Set @message = 'Invalid entry: dataset name is blank'
			End
			Else
			Begin
					
				EXEC @myError = dbo.CreatePredefinedAnalysesJobs 
												@datasetNum,
												@callingUser,
												@AnalysisToolNameFilter,
												@ExcludeDatasetsNotReleased,
												@PreventDuplicateJobs,
												@InfoOnly,
												@message output,
												@JobsCreated output

			End
		
			If @InfoOnly = 0
				UPDATE  dbo.T_Predefined_Analysis_Scheduling_Queue
				SET     Message = @message ,
						Result_Code = @myError,
						State = CASE WHEN @myError > 1 THEN 'Error' ELSE 'Complete' End,
						Jobs_Created = ISNULL(@JobsCreated, 0),
						Last_Affected = GetDate()
				WHERE   Item = @currentItemID
			
			Set @DatasetsProcessed = @DatasetsProcessed + 1
		End 
		
		If @MaxDatasetsToProcess > 0 And @DatasetsProcessed >= @MaxDatasetsToProcess
		Begin
			Set @done = 1
		End
	End 
	
	If @InfoOnly <> 0
	Begin
		If @DatasetsProcessed = 0
			Set @message = 'No candidates were found in T_Predefined_Analysis_Scheduling_Queue'
		Else
		Begin
			Set @message = 'Processed ' + Convert(varchar(12), @DatasetsProcessed) + ' dataset'
			If @DatasetsProcessed <> 1
				Set @message = @message + 's'
		End
		
		Print @message
	End

	RETURN 0



GO
GRANT VIEW DEFINITION ON [dbo].[CreatePendingPredefinedAnalysesTasks] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreatePendingPredefinedAnalysesTasks] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreatePendingPredefinedAnalysesTasks] TO [PNL\D3M580] AS [dbo]
GO
