/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunWP] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateRequestedRunWP
/****************************************************
**
**	Desc: 
**		Updates the work package for requested runs
**		from an old value to a new value
**
**		If @RequestedIdList is empty, then finds active requested runs that use @OldWorkPackage
**
**		If @RequestedIdList is defined, then finds all requested runs in the list that use @OldWorkPackage
**		regardless of the state
**
**		Changes will be logged to T_Log_Entries
**
**	Return values: 0: success, otherwise, error code
**
**	Auth: 	mem
**	Date: 	07/01/2014 mem - Initial version
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@OldWorkPackage varchar(50),
	@NewWorkPackage varchar(50),
	@RequestedIdList varchar(max) = '',		-- Optional: if blank, finds active requested runs; if defined, updates all of the specified request IDs if they use @OldWorkPackage
	@message varchar(512) output,
	@callingUser varchar(128) = '',
	@InfoOnly tinyint = 0
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Declare @RequestCountToUpdate int = 0

	Begin TRY 

		----------------------------------------------------------
		-- Validate the inputs
		----------------------------------------------------------
		
		Set @OldWorkPackage = dbo.ScrubWhitespace(@OldWorkPackage)
		Set @NewWorkPackage = dbo.ScrubWhitespace(@NewWorkPackage)
		Set @RequestedIdList = IsNull(@RequestedIdList, '')
		Set @message = ''
		Set @callingUser = IsNull(@callingUser, '')
		Set @InfoOnly = IsNull(@InfoOnly, 0)
		
		If @CallingUser = ''
			Set @CallingUser = Suser_sname()
			
		If @OldWorkPackage = ''
			RAISERROR ('Old work package cannot be blank', 11, 16)
		
		If @NewWorkPackage = ''
			RAISERROR ('Oew work package cannot be blank', 11, 16)

		----------------------------------------------------------
		-- Create some temporary tables
		----------------------------------------------------------
		--
		CREATE TABLE #Tmp_ReqRunsToUpdate (
			ID int not null,
		    RDS_Name varchar(128) not null,
		    RDS_WorkPackage varchar(50) not null
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_ReqRunsToUpdate ON #Tmp_ReqRunsToUpdate (ID)


		CREATE TABLE #Tmp_RequestedRunList (
			ID int not null
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_RequestedRunList ON #Tmp_RequestedRunList (ID)
		
		----------------------------------------------------------
		-- Find the Requested Runs to update
		----------------------------------------------------------
		--		
		If @RequestedIdList <> ''
		Begin
			
			-- Find requested runs using @RequestedIdList
			--		
			INSERT INTO #Tmp_RequestedRunList( ID )
			SELECT Value
			FROM dbo.udfParseDelimitedList ( @RequestedIdList, ',' )
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount


			Declare @RRCount int
			
			SELECT @RRCount = COUNT(*)
			FROM #Tmp_RequestedRunList

			If @RRCount = 0
				RAISERROR ('User supplied Requested Run IDs was empty or did not contain integers', 11, 16)

			
			INSERT INTO #Tmp_ReqRunsToUpdate( ID,
			                                  RDS_Name,
			                                  RDS_WorkPackage )
			SELECT RR.ID,
			       RR.RDS_Name,
			       RR.RDS_WorkPackage
			FROM T_Requested_Run RR
			     INNER JOIN #Tmp_RequestedRunList Filter
			       ON RR.ID = Filter.ID
			WHERE RR.RDS_WorkPackage = @OldWorkPackage
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			      
			Set @RequestCountToUpdate = @myRowcount

			If @RequestCountToUpdate = 0
			Begin
			    Set @message = 'None of the ' + Convert(varchar(12), @RRCount) + ' specified requested run IDs uses work package ' + @OldWorkPackage
			    If @InfoOnly <> 0
			        SELECT @message AS Message
			        
			    Goto done
			End
		End
		Else
		Begin
			-- Find active requested runs that use @OldWorkPackage
			--		

			INSERT INTO #Tmp_ReqRunsToUpdate( ID,
			                                  RDS_Name,
			                                  RDS_WorkPackage )
			SELECT ID,
			       RDS_Name,
			       RDS_WorkPackage
			FROM T_Requested_Run
			WHERE RDS_Status = 'active' AND
			      RDS_WorkPackage = @OldWorkPackage
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		
			Set @RequestCountToUpdate = @myRowcount
			
			If @RequestCountToUpdate = 0
			Begin
			    Set @message = 'Did not find any active requested runs with work package ' + @OldWorkPackage
			    If @InfoOnly <> 0
			        SELECT @message AS Message
			        
			    Goto done
			End
			
		End
		
		----------------------------------------------------------
		-- Generate log message that describes the requested runs that will be updated
		----------------------------------------------------------
		--			
		Create Table #Tmp_ValuesByCategory (
			Category varchar(512),
			Value int Not null
		)

		Create Table #Tmp_Condensed_Data (
			Category varchar(512),
			ValueList varchar(max)
		)
		
		INSERT INTO #Tmp_ValuesByCategory (Category, Value)
		SELECT 'RR', ID
		FROM #Tmp_ReqRunsToUpdate
		ORDER BY ID
		
		Exec CondenseIntegerListToRanges @debugMode=0

		Declare @LogMessage varchar(2048)
		If @InfoOnly = 0
			Set @LogMessage = 'Updated '
		Else
			Set @LogMessage = 'Will update '	
						
		Set @LogMessage = @LogMessage + 'work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.CheckPlural(@myRowCount, 'run', 'runs')
		Set @LogMessage = @LogMessage + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage
		
		Declare @ValueList varchar(max)
		
		SELECT TOP 1 @ValueList = ValueList
		FROM #Tmp_Condensed_Data
		
		Set @LogMessage = @LogMessage + '; user ' + @CallingUser + '; IDs ' + IsNull(@ValueList, '??')


		If @InfoOnly <> 0
		Begin
			----------------------------------------------------------
			-- Preview what would be updated
			----------------------------------------------------------
			--
			SELECT @LogMessage as Log_Message
			
			SELECT ID,
			       RDS_Name AS Request_Name,
			       RDS_WorkPackage AS Old_Work_Package,
			       @NewWorkPackage AS New_Work_Package
			FROM #Tmp_ReqRunsToUpdate
			ORDER BY ID
		
			Set @message = 'Will update work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.CheckPlural(@myRowCount, 'run', 'runs') + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage
				
		End
		Else
		Begin
			----------------------------------------------------------
			-- Perform the update
			----------------------------------------------------------
			--
		
			UPDATE T_Requested_Run
			Set RDS_WorkPackage = @NewWorkPackage
			FROM T_Requested_Run Target
				INNER JOIN #Tmp_ReqRunsToUpdate src
				ON Target.ID = Src.ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			Set @message = 'Updated work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.CheckPlural(@myRowCount, 'run', 'runs') + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage
			
			Exec PostLogEntry 'Normal', @LogMessage, 'UpdateRequestedRunWP'
			
		End

	End TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	End CATCH

Done:

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunWP] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunWP] TO [DMS2_SP_User] AS [dbo]
GO
