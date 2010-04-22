/****** Object:  StoredProcedure [dbo].[AlterEventLogEntryUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AlterEventLogEntryUser
/****************************************************
**
**	Desc:	Updates the user associated with a given event log entry to be @NewUser
**
**			If @ApplyTimeFilter is non-zero, then only matches entries made within the last
**			  @EntryTimeWindowSeconds seconds
**
**			Use @infoOnly = 1 to preview updates
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
	@TargetID int,
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

	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------
	
	Set @NewUser = IsNull(@NewUser, '')
	Set @ApplyTimeFilter = IsNull(@ApplyTimeFilter, 0)
	Set @EntryTimeWindowSeconds = IsNull(@EntryTimeWindowSeconds, 15)
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)

	If @TargetType Is Null Or @TargetID Is Null Or @TargetState Is Null
	Begin
		Set @message = '@TargetType and @TargetID and @TargetState must be defined; unable to continue'
		Set @myError = 50201
		Goto done
	End
	
	If Len(@NewUser) = 0
	Begin
		Set @message = '@NewUser is empty; unable to continue'
		Set @myError = 50202
		Goto done
	End

	Set @EntryDescription = 'ID ' + Convert(varchar(12), @TargetID) + ' (type ' + Convert(varchar(12), @TargetType) + ') with state ' + Convert(varchar(12), @TargetState)
	If @ApplyTimeFilter <> 0 And IsNull(@EntryTimeWindowSeconds, 0) >= 1
	Begin
		------------------------------------------------
		-- Filter using the current date/time
		------------------------------------------------
		--
		Set @EntryDateStart = DateAdd(second, -@EntryTimeWindowSeconds, @CurrentTime)
		Set @EntryDateEnd = DateAdd(second, 1, @CurrentTime)
		
		If @infoOnly <> 0
			Print 'Filtering on entries dated between ' + Convert(varchar(64), @EntryDateStart, 120) + ' and ' + Convert(varchar(64), @EntryDateEnd, 120) + ' (Window = ' + Convert(varchar(12), @EntryTimeWindowSeconds) + ' seconds)'
			
		SELECT @EntryIndex = EL.[Index], 
			   @EnteredBy = EL.Entered_By
		FROM T_Event_Log EL INNER JOIN
				(SELECT MAX([Index]) AS [Index]
				 FROM dbo.T_Event_Log
				 WHERE Target_Type = @TargetType AND 
				       Target_ID = @TargetID AND 
					   Target_State = @TargetState AND
					   Entered Between @EntryDateStart And @EntryDateEnd
				) LookupQ ON EL.[Index] = LookupQ.[Index]
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @EntryDescription = @EntryDescription + ' and Entry Time between ' + Convert(varchar(64), @EntryDateStart, 120) + ' and ' + Convert(varchar(64), @EntryDateEnd, 120)
	End
	Else
	Begin
		------------------------------------------------
		-- Do not filter by time
		------------------------------------------------
		--
		SELECT @EntryIndex = EL.[Index], 
			   @EnteredBy = EL.Entered_By
		FROM T_Event_Log EL INNER JOIN
				(SELECT MAX([Index]) AS [Index]
				 FROM dbo.T_Event_Log
				 WHERE Target_Type = @TargetType AND 
				       Target_ID = @TargetID AND 
					   Target_State = @TargetState
				) LookupQ ON EL.[Index] = LookupQ.[Index]
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End

	If @myError <> 0
	Begin
		Set @message = 'Error looking for ' + @EntryDescription
		Goto done
	End
	
	If @myRowCount <= 0
		Set @message = 'Match not found for ' + @EntryDescription
	Else
	Begin
		-- Confirm that @EnteredBy doesn't already contain @NewUser
		-- If it does, then there's no need to update it
		
		Set @MatchIndex = CharIndex(@NewUser, @EnteredBy)
		If @MatchIndex > 0
		Begin
			Set @message = 'Entry ' + @EntryDescription + ' is already attributed to ' + @NewUser + ': "' + @EnteredBy + '"'
			Goto Done
		End
		
		-- Look for a semicolon in @EnteredBy
			
		Set @MatchIndex = CharIndex(';', @EnteredBy)

		If @MatchIndex > 0
			Set @EnteredByNew = @NewUser + ' (via ' + SubString(@EnteredBy, 1, @MatchIndex-1) + ')' + SubString(@EnteredBy, @MatchIndex, Len(@EnteredBy))
		Else
			Set @EnteredByNew = @NewUser + ' (via ' + @EnteredBy + ')'
		
		If Len(IsNull(@EnteredByNew, '')) > 0
		Begin

			If @infoOnly = 0
			Begin
				UPDATE T_Event_Log
				SET Entered_By = @EnteredByNew
				WHERE [Index] = @EntryIndex
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myError <> 0
				Begin
					Set @message = 'Error updating ' + @EntryDescription
					Exec PostLogEntry 'Error', @message, 'AlterEventLogEntryUser'
					Goto Done
				End
				Else
					Set @message = 'Updated ' + @EntryDescription + ' to indicate "' + @EnteredByNew + '"'
			End
			Else
			Begin
				SELECT [Index], Target_Type, Target_ID, Target_State, 
					   Prev_Target_State, Entered, 
					   Entered_By AS Entered_By_Old,
					   @EnteredByNew AS Entered_By_New
				FROM T_Event_Log
				WHERE [Index] = @EntryIndex
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				Set @message = 'Would update ' + @EntryDescription + ' to indicate "' + @EnteredByNew + '"'
			End

		End
		Else
			Set @Message = 'Match not found; unable to continue'

	End
	
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AlterEventLogEntryUser] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AlterEventLogEntryUser] TO [PNL\D3M580] AS [dbo]
GO
