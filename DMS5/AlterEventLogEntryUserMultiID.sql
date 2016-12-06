/****** Object:  StoredProcedure [dbo].[AlterEventLogEntryUserMultiID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AlterEventLogEntryUserMultiID
/****************************************************
**
**	Desc:	Calls AlterEventLogEntryUser for each entry in #TmpIDUpdateList
**
**			The calling procedure must create and populate temporary table #TmpIDUpdateList:
**				CREATE TABLE #TmpIDUpdateList (
**					TargetID int NOT NULL
**				)
**
**			Increased performance can be obtained by adding an index to the table; thus
**			it is advisable that the calling procedure also create this index:		
**				CREATE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/29/2008 mem - Initial version (Ticket: #644)
**			05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**    
*****************************************************/
(
	@TargetType smallint,				-- 1=Campaign, 2=Cell Culture, 3=Experiment, 4=Dataset, 5=Analysis Job, 6=Archive, 7=Archive Update, 8=Dataset Rating
	@TargetState int,
	@NewUser varchar(128),
	@ApplyTimeFilter tinyint = 1,		-- If 1, then filters by the current date and time; if 0, looks for the most recent matching entry
	@EntryTimeWindowSeconds int = 15,	-- Only used if @ApplyTimeFilter = 1
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @EntryDateStart datetime
	Declare @EntryDateEnd datetime

	Declare @EntryDescription varchar(512)
	Declare @EntryIndex int
	Declare @MatchIndex int
	
	Declare @EnteredBy varchar(255)
	Declare @EnteredByNew varchar(255)
	Set @EnteredByNew = ''
	
	Declare @CurrentTime datetime
	Set @CurrentTime = GetDate()

	Declare @TargetID int
	Declare @CountUpdated int
	Declare @Continue tinyint

	Declare @StartTime datetime
	Declare @EntryTimeWindowSecondsCurrent int
	Declare @ElapsedSeconds int
	
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------
	
	Set @NewUser = IsNull(@NewUser, '')
	Set @ApplyTimeFilter = IsNull(@ApplyTimeFilter, 0)
	Set @EntryTimeWindowSeconds = IsNull(@EntryTimeWindowSeconds, 15)
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)

	If @TargetType Is Null Or @TargetState Is Null
	Begin
		Set @message = '@TargetType and @TargetState must be defined; unable to continue'
		Set @myError = 50201
		Goto done
	End
	
	If Len(@NewUser) = 0
	Begin
		Set @message = '@NewUser is empty; unable to continue'
		Set @myError = 50202
		Goto done
	End

	-- Make sure #TmpIDUpdateList is not empty
	SELECT @myRowCount = COUNT(*)
	FROM #TmpIDUpdateList
	
	If @myRowCount <= 0
	Begin
		Set @message = '#TmpIDUpdateList is empty; nothing to do'
		Goto done
	End

	------------------------------------------------
	-- Initialize @EntryTimeWindowSecondsCurrent
	-- This variable will be automatically increased 
	--  if too much time elapses
	------------------------------------------------
	--
	Set @StartTime = GetDate()
	Set @EntryTimeWindowSecondsCurrent = @EntryTimeWindowSeconds
	
	------------------------------------------------
	-- Determine the minimum value in #TmpIDUpdateList
	------------------------------------------------

	SELECT @TargetID = Min(TargetID)-1
	FROM #TmpIDUpdateList
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	Set @TargetID = IsNull(@TargetID, -1)
	
	------------------------------------------------
	-- Parse the values in #TmpIDUpdateList
	-- Call AlterEventLogEntryUser for each
	------------------------------------------------
	
	Set @CountUpdated = 0
	Set @Continue = 1
	
	While @Continue = 1
	Begin
		SELECT TOP 1 @TargetID = TargetID
		FROM #TmpIDUpdateList
		WHERE TargetID > @TargetID
		ORDER BY TargetID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		If @myRowCount = 0
			Set @continue = 0
		Else
		Begin
			Exec @myError = AlterEventLogEntryUser
								@TargetType,
								@TargetID,
								@TargetState,
								@NewUser,
								@ApplyTimeFilter,
								@EntryTimeWindowSeconds,
								@message output,
								@infoOnly

			If @myError <> 0
				Goto Done
			
			Set @CountUpdated = @CountUpdated + 1
			If @CountUpdated % 5 = 0
			Begin
				Set @ElapsedSeconds = DateDiff(second, @StartTime, GetDate())
				
				If @ElapsedSeconds * 2 > @EntryTimeWindowSecondsCurrent
					Set @EntryTimeWindowSecondsCurrent = @ElapsedSeconds * 4
			End
		End
	End
	
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AlterEventLogEntryUserMultiID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AlterEventLogEntryUserMultiID] TO [Limited_Table_Write] AS [dbo]
GO
