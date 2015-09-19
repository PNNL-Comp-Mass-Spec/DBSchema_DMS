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
**			09/17/2015 mem - Added parameter @infoOnly
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) = '' output,
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5,		-- Seconds between detailed logging while looping through the dependencies
	@infoOnly tinyint = 0,				-- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
	@DebugMode tinyint = 0				-- 0 for no debugging; 1 to see debug messages
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
	--
	Set @infoOnly = IsNull(@infoOnly, 0)
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
	--  Add new jobs
	---------------------------------------------------
	--
	IF @bypassDMS = 0
	BEGIN -- <AddJobs>
	
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @StatusMessage = 'Querying DMS'
			exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewArchiveJobsFromDMS'
		End

		If @infoOnly = 0
		Begin -- <InsertQuery>
			
			INSERT INTO T_Jobs (Script,
								[Comment],
								Dataset,
								Dataset_ID,
								Priority )
			SELECT 'DatasetArchive' AS Script,
				'Created by import from DMS' AS [Comment],
				Src.Dataset,
				Src.Dataset_ID,
				2 AS Priority
			FROM V_DMS_Get_New_Archive_Datasets Src LEFT OUTER JOIN
			     T_Jobs Target ON Src.Dataset_ID = Target.Dataset_ID AND Target.Script = 'DatasetArchive'
			WHERE Target.Dataset_ID Is Null
			
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error creating archive jobs'
				goto Done
			end
			
		End -- </InsertQuery>
		Else
		Begin -- <Preview>

			SELECT 'DatasetArchive' AS Script,
				'Created by import from DMS' AS [Comment],
				Src.Dataset,
				Src.Dataset_ID,
				2 AS Priority
			FROM V_DMS_Get_New_Archive_Datasets Src LEFT OUTER JOIN
			     T_Jobs Target ON Src.Dataset_ID = Target.Dataset_ID AND Target.Script = 'DatasetArchive'
			WHERE Target.Dataset_ID Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
		End -- </Preview>
		
	END -- </AddJobs>

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
