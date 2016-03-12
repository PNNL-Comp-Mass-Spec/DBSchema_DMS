/****** Object:  StoredProcedure [dbo].[AlterEnteredByUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AlterEnteredByUser
/****************************************************
**
**	Desc:	Updates the Entered_By column for the specified row in the given table to be @NewUser
**
**			If @ApplyTimeFilter is non-zero, then only matches entries made within the last
**			  @EntryTimeWindowSeconds seconds
**
**			Use @infoOnly = 1 to preview updates
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/25/2008 mem - Initial version (Ticket: #644)
**			05/23/2008 mem - Expanded @EntryDescription to varchar(512)
**    
*****************************************************/
(
	@TargetTableName varchar(128),
	@TargetIDColumnName varchar(128),
	@TargetID int,
	@NewUser varchar(128),
	@ApplyTimeFilter tinyint = 1,		-- If 1, then filters by the current date and time; if 0, looks for the most recent matching entry
	@EntryTimeWindowSeconds int = 15,	-- Only used if @ApplyTimeFilter = 1
	@EntryDateColumnName varchar(128) = 'Entered',
	@EnteredByColumnName varchar(128) = 'Entered_By',
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0,
	@PreviewSql tinyint = 0
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

	declare @S nvarchar(3000)

	declare @EntryFilterSql nvarchar(512)
	Set @EntryFilterSql = ''
	
	declare @ParamDef nvarchar(512)
	declare @result int
	declare @TargetIDMatch int
		
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------
	
	Set @NewUser = IsNull(@NewUser, '')
	Set @ApplyTimeFilter = IsNull(@ApplyTimeFilter, 0)
	Set @EntryTimeWindowSeconds = IsNull(@EntryTimeWindowSeconds, 15)
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @PreviewSql = IsNull(@PreviewSql, 0)

	If @TargetTableName Is Null Or @TargetIDColumnName Is Null Or @TargetID Is Null
	Begin
		Set @message = '@TargetTableName and @TargetIDColumnName and @TargetID must be defined; unable to continue'
		Set @myError = 50201
		Goto done
	End
	
	If Len(@NewUser) = 0
	Begin
		Set @message = '@NewUser is empty; unable to continue'
		Set @myError = 50202
		Goto done
	End

	Set @EntryDescription = 'ID ' + Convert(varchar(12), @TargetID) + ' in table ' + @TargetTableName + ' (column ' + @TargetIDColumnName + ')'

	Set @S = ''
	Set @S = @S + '	SELECT @TargetIDMatch = [' + @TargetIDColumnName + '],'
	Set @S = @S +        ' @EnteredBy = [' + @EnteredByColumnName + ']'
	Set @S = @S + ' FROM [' + @TargetTableName + ']'
	Set @S = @S + ' WHERE [' + @TargetIDColumnName + '] = ' + Convert(varchar(12), @TargetID)

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
		
		Set @EntryFilterSql = ' [' + @EntryDateColumnName + '] Between ''' + Convert(varchar(64), @EntryDateStart, 120) + ''' And ''' + Convert(varchar(64), @EntryDateEnd, 120) + ''''
		Set @S = @S + ' AND ' + @EntryFilterSql
		
		Set @EntryDescription = @EntryDescription + ' with ' + @EntryFilterSql
	End

	Set @ParamDef = '@TargetIDMatch int output, @EnteredBy varchar(128) output'

	If @PreviewSql <> 0
	Begin
		Print @S
		Set @EnteredBy = suser_sname() + '_Simulated'
	End
	Else
		Exec @result = sp_executesql @S, @ParamDef, @TargetIDMatch = @TargetIDMatch output, @EnteredBy = @EnteredBy output
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	If @myError <> 0
	Begin
		Set @message = 'Error looking for ' + @EntryDescription
		Goto done
	End
	
	If @PreviewSql = 0 AND (@myRowCount <= 0 Or @TargetIDMatch <> @TargetID)
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
				Set @S = ''
				Set @S = @S + ' UPDATE [' + @TargetTableName + ']'
				Set @S = @S + ' SET [' + @EnteredByColumnName + '] = ''' + @EnteredByNew + ''''
				Set @S = @S + ' WHERE [' + @TargetIDColumnName + '] = ' + Convert(varchar(12), @TargetID)
				
				If Len(@EntryFilterSql) > 0
					Set @S = @S + ' AND ' + @EntryFilterSql

				If @PreviewSql <> 0
					Print @S
				Else
					Exec (@S)
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
				Set @S = ''
				Set @S = @S + ' SELECT *, ''' + @EnteredByNew + ''' AS Entered_By_New'
				Set @S = @S + ' FROM [' + @TargetTableName + ']'
				Set @S = @S + ' WHERE [' + @TargetIDColumnName + '] = ' + Convert(varchar(12), @TargetID)

				If Len(@EntryFilterSql) > 0
					Set @S = @S + ' AND ' + @EntryFilterSql

				If @PreviewSql <> 0
					Print @S
				Else
					Exec (@S)
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
GRANT VIEW DEFINITION ON [dbo].[AlterEnteredByUser] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AlterEnteredByUser] TO [PNL\D3M578] AS [dbo]
GO
