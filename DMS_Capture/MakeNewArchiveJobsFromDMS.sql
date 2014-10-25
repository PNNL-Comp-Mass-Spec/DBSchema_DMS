/****** Object:  StoredProcedure [dbo].[MakeNewArchiveJobsFromDMS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeNewArchiveJobsFromDMS
/****************************************************
**
**	Desc:
**    Add dataset archive jobs from DMS 
**    for datsets that are in archive “New” state that aren’t
**    already in table.
**
**	Auth:	grk
**	Date:	01/08/2010 grk - Initial release 
**			10/24/2014 mem - Changed priority to 2
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) = '' output,
	@DebugMode tinyint = 0,
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @currJob int
	declare @Dataset varchar(128)
	declare @continue tinyint

	declare @JobsProcessed int
	Declare @JobCountToResume int
	declare @JobCountToReset int
	
	Declare @MaxJobsToAddResetOrResume int

	declare @StartTime datetime
	declare @LastLogTime datetime
	declare @StatusMessage varchar(512)	
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Set @bypassDMS = IsNull(@bypassDMS, 0)
	Set @DebugMode = IsNull(@DebugMode, 0)
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)
	
	set @message = ''

	If @MaxJobsToProcess <= 0
		Set @MaxJobsToAddResetOrResume = 1000000
	Else
		Set @MaxJobsToAddResetOrResume = @MaxJobsToProcess

	Set @StartTime = GetDate()
	Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
	Set @LogIntervalThreshold = IsNull(@LogIntervalThreshold, 15)
	Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
	
	If @LogIntervalThreshold = 0
		Set @LoggingEnabled = 1
		
	If @LoopingUpdateInterval < 2
		Set @LoopingUpdateInterval = 2

	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @StatusMessage = 'Entering (' + CONVERT(VARCHAR(12), @bypassDMS) + ')'
		exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewArchiveJobsFromDMS'
	End
	
	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	IF @bypassDMS = 0
	BEGIN
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @StatusMessage = 'Querying DMS'
			exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewArchiveJobsFromDMS'
		End

		INSERT INTO T_Jobs (Script,
		                    [Comment],
		                    Dataset,
		                    Dataset_ID,
		                    Priority )
		SELECT 'DatasetArchive' AS Script,
		       'Created by import from DMS' AS [Comment],
		       Dataset,
		       Dataset_ID,
		       2 AS Priority
		FROM V_DMS_Get_New_Archive_Datasets
		WHERE (NOT EXISTS ( SELECT Job
		                    FROM T_Jobs
		                    WHERE (Dataset_ID = V_DMS_Get_New_Archive_Datasets.Dataset_ID) AND
		                          (Script = 'DatasetArchive') 
		      ) )

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error creating archive jobs'
			goto Done
		end
	END

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @StatusMessage = 'Exiting'
		exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewArchiveJobsFromDMS'
	End

	If @DebugMode <> 0
		SELECT *
		FROM #Tmp_JobDebugMessages
		ORDER BY EntryID

	return @myError

GO
