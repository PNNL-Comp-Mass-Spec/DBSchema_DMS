/****** Object:  StoredProcedure [dbo].[ManageJobState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ManageJobState
/****************************************************
**
**	Desc:
**  Change state of existing capture jobs according to
**  changes in dataset state in DMS
**
**	Auth:	grk
**	09/15/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
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
	if @bypassDMS <> 0
		goto Done

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
	
	---------------------------------------------------
	-- look for new or held jobs for datasets already
	-- in the job table
	---------------------------------------------------
	--
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating Resume jobs'
		goto Done
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @DebugMode <> 0
		SELECT *
		FROM #Tmp_JobDebugMessages
		ORDER BY EntryID

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobState] TO [DDL_Viewer] AS [dbo]
GO
