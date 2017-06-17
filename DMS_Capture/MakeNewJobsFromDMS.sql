/****** Object:  StoredProcedure [dbo].[MakeNewJobsFromDMS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeNewJobsFromDMS
/****************************************************
**
**	Desc:
**    Add dataset capture jobs from DMS for datsets that are in “New” state that aren’t
**    already in table.  Choose script..
**
**	Auth:	grk
**	Date:	09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			02/10/2010 dac - Removed comment stating that jobs were created from test script
**			03/09/2011 grk - Added logic to choose different capture script based on instrument group
**			09/17/2015 mem - Added parameter @infoOnly
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
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
	
	declare @myError int = 0
	declare @myRowCount int = 0

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
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'MakeNewJobsFromDMS', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End
		
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
		exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewJobsFromDMS'
	End
	
	---------------------------------------------------
	-- Add new jobs
	---------------------------------------------------
	--
	IF @bypassDMS = 0
	BEGIN -- <AddJobs>
	
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @StatusMessage = 'Querying DMS'
			exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewJobsFromDMS'
		End

		If @infoOnly = 0
		Begin -- <InsertQuery>
		
			INSERT INTO T_Jobs( Script,
								[Comment],
								Dataset,
								Dataset_ID )
			SELECT CASE
					WHEN Src.IN_Group = 'IMS' THEN 'IMSDatasetCapture'
					ELSE 'DatasetCapture'
				END AS Script,
				'' AS [Comment],
				Src.Dataset,
				Src.Dataset_ID
			FROM V_DMS_Get_New_Datasets Src LEFT OUTER JOIN
			     T_Jobs Target ON Src.Dataset_ID = Target.Dataset_ID
			WHERE Target.Dataset_ID Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error adding new DatasetCapture tasks'
				goto Done
			end
			
		End -- </InsertQuery>
		Else
		Begin -- <Preview>

			SELECT CASE
					WHEN Src.IN_Group = 'IMS' THEN 'IMSDatasetCapture'
					ELSE 'DatasetCapture'
				END AS Script,
				'' AS [Comment],
				Src.Dataset,
				Src.Dataset_ID
			FROM V_DMS_Get_New_Datasets Src LEFT OUTER JOIN
			     T_Jobs Target ON Src.Dataset_ID = Target.Dataset_ID
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
		exec PostLogEntry 'Progress', @StatusMessage, 'MakeNewJobsFromDMS'
	End

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNewJobsFromDMS] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakeNewJobsFromDMS] TO [DMS_SP_User] AS [dbo]
GO
