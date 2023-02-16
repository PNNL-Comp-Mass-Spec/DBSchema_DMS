/****** Object:  StoredProcedure [dbo].[UpdateUserPermissionsViewDefinitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateUserPermissionsViewDefinitions
/****************************************************
**
**	Desc: Grants view definition permission to all stored procedures and views for the specified roles or users
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	11/04/2008
**			12/28/2009 mem - Updated to also update views (and to include parameters @updateSPs and @updateViews)
**			02/23/2016 mem - Add set XACT_ABORT on
**			12/06/2016 mem - Rename @userList to @roleOrUserList and add @revokeList, @updateTables, and @updateOther
**    
*****************************************************/
(
	@roleOrUserList varchar(255) = 'DDL_Viewer',
	@revokeList varchar(255) = 'PNL\D3M578, PNL\D3M580',
	@updateTables tinyint = 1,
	@updateSPs tinyint = 1,
	@updateViews tinyint = 1,
	@updateOther tinyint = 1,
	@PreviewSql tinyint = 0,
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Set NoCount On
	
	Declare @action varchar(12)
	Declare @Continue1 int
	Declare @Continue2 int
	Declare @Continue3 int
	
	Declare @S varchar(1024)
	Declare @LoginUniqueID int
	Declare @LoginName varchar(255)
	
	Declare @ObjectName sysname
	Declare @ObjectUniqueID int
	Declare @ObjectUpdateCount int
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
		
		------------------------------------------------
		-- Validate the inputs
		------------------------------------------------
		
		Set @roleOrUserList = IsNull(@roleOrUserList, '')
		Set @revokeList = IsNull(@revokeList, '')
		
		Set @updateTables = IsNull(@updateTables, 1)
		Set @updateSPs = IsNull(@updateSPs, 1)
		Set @updateViews = IsNull(@updateViews, 1)
		Set @updateOther = IsNull(@updateOther, 1)
		
		Set @PreviewSql = IsNull(@PreviewSql, 0)
		Set @message = ''
		
		------------------------------------------------
		-- Create a temporary table to hold the items in @roleOrUserList and @revokeList
		------------------------------------------------
		--
		CREATE TABLE #TmpLoginsToProcess (
			UniqueID int Identity(1,1),
			LoginName varchar(255),
			Action varchar(12)
		)
		
		Set @CurrentLocation = 'Parse @roleOrUserList'
		
		INSERT INTO #TmpLoginsToProcess (LoginName, Action)
		SELECT Value, 'Grant'
		FROM dbo.udfParseDelimitedList(@roleOrUserList, ',')
		ORDER BY Value
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		Set @CurrentLocation = 'Parse @revokeList'
		
		INSERT INTO #TmpLoginsToProcess (LoginName, Action)
		SELECT Value, 'Revoke'
		FROM dbo.udfParseDelimitedList(@revokeList, ',')
		ORDER BY Value
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If Not Exists (Select * FROM #TmpLoginsToProcess)
		Begin
			Set @Message = '@roleOrUserList and @revokeList were both empty; nothing to do'
			Goto Done
		End


		------------------------------------------------
		-- Cache the names of objects to update
		------------------------------------------------
		--
		CREATE TABLE #TmpObjectsToUpdate (
			UniqueID int Identity(1,1),
			[Name] sysname,
			[object_id] int
		)
		
		CREATE CLUSTERED INDEX #IX_TmpObjectsToUpdate_UniqueID ON #TmpObjectsToUpdate (UniqueID)
		CREATE Unique INDEX #IX_TmpObjectsToUpdate_ObjectID ON #TmpObjectsToUpdate ([object_id])
		
		If @updateTables > 0
		Begin
			Insert Into #TmpObjectsToUpdate ([Name], [object_id])
			Select [Name], [object_id]
			From sys.objects
			Where type In ('U')
			Order By Name
		End

		If @updateSPs > 0
		Begin
			Insert Into #TmpObjectsToUpdate ([Name], [object_id])
			Select [Name], [object_id]
			From sys.objects
			Where type In ('P')
			Order By Name
		End

		If @updateViews > 0
		Begin
			Insert Into #TmpObjectsToUpdate ([Name], [object_id])
			Select [Name], [object_id]
			From sys.objects
			Where type In ('SN','V')
			Order By Name

		end

		If @updateOther > 0
		Begin
			Insert Into #TmpObjectsToUpdate ([Name], [object_id])
			Select [Name], [object_id]
			From sys.objects
			Where type In ('FN','TF')
			Order By Name
		End

		If @PreviewSql > 0
		Begin
			SELECT OU.*, O.type, O.type_desc
			FROM #TmpObjectsToUpdate OU
			INNER JOIN sys.objects O ON OU.object_id = O.object_id
			Order by o.type, OU.Name
		End
			
		------------------------------------------------
		-- First process each login in #TmpRevokeList
		-- Next, process each login in #TmpLoginsToProcess
		------------------------------------------------
		--
		
		Set @Continue1 = 1
		While @Continue1 <= 2
		Begin
			
			If @Continue1 = 1
			Begin
				Set @CurrentLocation = 'Process each revoke in #TmpLoginsToProcess'
				Set @action = 'Revoke'
				Print @CurrentLocation
			End
			
			If @Continue1 = 2				
			Begin
				Set @CurrentLocation = 'Process each grant in #TmpLoginsToProcess'
				Set @action = 'Grant'
				Print @CurrentLocation
			End			
			
			Set @LoginUniqueID = 0
			
			Set @Continue2 = 1
			While @Continue2 = 1
			Begin -- <b>
			
				SELECT TOP 1 @LoginUniqueID = UniqueID,
							 @LoginName = LoginName		   
				FROM #TmpLoginsToProcess
				WHERE UniqueID > @LoginUniqueID and Action = @action
				ORDER BY UniqueID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

				If @myRowCount = 0
					Set @Continue2 = 0
				Else
				Begin -- <c>
					Print 'Process login ' + @LoginName + ' for ' + @action
					
					------------------------------------------------
					-- Grant/Revoke ShowPlan for login @LoginName
					------------------------------------------------
			
					Set @S = @action + ' showplan to [' + @LoginName + ']'
					Set @CurrentLocation = @S

					If @PreviewSql <> 0
						Print @S
					Else
						Exec (@S)
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					
					If @myError <> 0
					Begin
						Set @message = 'Error executing "' + @S + '"'
						Goto Done
					End

					------------------------------------------------
					-- Process each object in #TmpObjectsToUpdate
					------------------------------------------------
					
					Set @CurrentLocation = 'Process each object in #TmpObjectsToUpdate'
			
					Set @ObjectUniqueID = 0
					Set @ObjectUpdateCount = 0
					
					Set @Continue3 = 1
					While @Continue3 = 1
					Begin -- <e1>
						SELECT TOP 1 @ObjectUniqueID = UniqueID,
						             @ObjectName = Name
						FROM #TmpObjectsToUpdate
						WHERE UniqueID > @ObjectUniqueID
						ORDER BY UniqueID
						--
						SELECT @myError = @@error, @myRowCount = @@rowcount

						If @myRowCount = 0
							Set @Continue3 = 0
						Else
						Begin -- <f1>
							Set @S = @action + ' view definition on [' + @ObjectName + '] to [' + @LoginName + ']'
							Set @CurrentLocation = @S

							If @PreviewSql <> 0
								Print @S
							Else
								Exec (@S)
												
							Set @ObjectUpdateCount = @ObjectUpdateCount + 1
							
						End -- </f1>				
					End -- </e1>
				
					If @message <> ''
						Set @message = @message + '; '
						
					Set @message = @message + 'Updated ' + Convert(varchar(12), @ObjectUpdateCount) + ' objects for [' + @LoginName + '] with ' + @action
					
				End -- </c>
			End -- </b>
			
			Set @Continue1 = @Continue1 + 1
		End -- </a>
		
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateUserPermissionsViewDefinitions')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, @LogWarningErrorList = '',
								@ErrorNum = @myError output, @message = @message output
		Goto Done
	End Catch

Done:
	Print @message
	
	Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUserPermissionsViewDefinitions] TO [DDL_Viewer] AS [dbo]
GO
