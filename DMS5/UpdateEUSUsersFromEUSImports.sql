/****** Object:  StoredProcedure [dbo].[UpdateEUSUsersFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure dbo.UpdateEUSUsersFromEUSImports
/****************************************************
**
**	Desc: 
**  Updates associated EUS user associations for
**  proposals that are currently active in DMS
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/01/2006 grk - Initial version
**			03/24/2011 mem - Updated to use V_EUS_Import_Proposal_Participants
**			03/25/2011 mem - Updated to remove entries from T_EUS_Proposal_Users if the row is no longer in V_EUS_Import_Proposal_Participants yet the proposal is still active
**			04/01/2011 mem - No longer removing entries from T_EUS_Proposal_Users; now changing to state 5="No longer associated with proposal"
**						   - Added support for state 4="Permanently associated with proposal"
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			03/19/2012 mem - Now populating T_EUS_Users.HID
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @MergeUpdateCount int
	Declare @MergeInsertCount int
	Declare @MergeDeleteCount int
	
	Set @MergeUpdateCount = 0
	Set @MergeInsertCount = 0
	Set @MergeDeleteCount = 0

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try

		---------------------------------------------------
		-- Create the temporary table that will be used to
		-- track the number of inserts, updates, and deletes 
		-- performed by the MERGE statement
		---------------------------------------------------
		
		CREATE TABLE #Tmp_UpdateSummary (
			UpdateAction varchar(32)
		)
		
		CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)

		Set @CurrentLocation = 'Update T_EUS_Users'
		
		---------------------------------------------------
		-- Use a MERGE Statement to synchronize 
		-- T_EUS_User with V_EUS_Import_Proposal_Participants
		---------------------------------------------------

		MERGE T_EUS_Users AS target
		USING 
			(
			   SELECT DISTINCT Source.PERSON_ID,
			                   Source.NAME_FM,
			                   CASE WHEN HANFORD_ID IS NULL
			                        THEN NULL
			                        ELSE 'H' + HANFORD_ID
			                        END AS HID,
			                   CASE WHEN HANFORD_ID IS NULL 
			                        THEN 2		-- Offsite
			                        ELSE 1		-- Onsite
			                        END as Site_Status
			   FROM dbo.V_EUS_Import_Proposal_Participants Source
			        INNER JOIN ( SELECT PROPOSAL_ID
			                     FROM T_EUS_Proposals
			                     WHERE State_ID IN (1,2)
			                    ) DmsEUSProposals
			          ON Source.PROPOSAL_ID = DmsEUSProposals.PROPOSAL_ID
			) AS Source (	PERSON_ID, NAME_FM, HID, Site_Status)
		ON (target.PERSON_ID = source.PERSON_ID)
		WHEN Matched AND 
					(	target.NAME_FM <> source.NAME_FM OR
						(IsNull(target.HID, '') <> source.HID AND NOT source.HID is null) OR
						target.Site_Status <> source.Site_Status
					)
			THEN UPDATE 
				Set	NAME_FM = source.NAME_FM, 
					HID = IsNull(source.HID, target.HID),
					Site_Status = source.Site_Status,
					Last_Affected = GetDate()
		WHEN Not Matched THEN
			INSERT (PERSON_ID, NAME_FM, HID, Site_Status, Last_Affected)
			VALUES (source.PERSON_ID, source.NAME_FM, source.HID, source.Site_Status, GetDate())
		-- Note: don't delete data from T_EUS_Users
		-- WHEN NOT MATCHED BY SOURCE THEN
		--  could DELETE
		OUTPUT $action INTO #Tmp_UpdateSummary
		;
	
		if @myError <> 0
		begin
			set @message = 'Error merging V_EUS_Import_Proposal_Participants with T_EUS_Users (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateEUSUsersFromEUSImports'
			goto Done
		end


		set @MergeUpdateCount = 0
		set @MergeInsertCount = 0
		set @MergeDeleteCount = 0

		SELECT @MergeInsertCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'INSERT'

		SELECT @MergeUpdateCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'UPDATE'

		SELECT @MergeDeleteCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'DELETE'
		
		If @MergeUpdateCount > 0 OR @MergeInsertCount > 0 OR @MergeDeleteCount > 0
		Begin
			Set @message = 'Updated T_EUS_Users: ' + Convert(varchar(12), @MergeInsertCount) + ' added; ' + Convert(varchar(12), @MergeUpdateCount) + ' updated'
			
			If @MergeDeleteCount > 0
				Set @message = @message + '; ' + Convert(varchar(12), @MergeDeleteCount) + ' deleted'
				
			Exec PostLogEntry 'Normal', @message, 'UpdateEUSUsersFromEUSImports'
			Set @message = ''
		End
		
		
		Set @CurrentLocation = 'Update T_EUS_Proposal_Users'
		
		---------------------------------------------------
		-- Use a MERGE Statement to synchronize 
		-- T_EUS_User with V_EUS_Import_Proposal_Participants
		---------------------------------------------------

		DELETE FROM #Tmp_UpdateSummary

		MERGE T_EUS_Proposal_Users AS target
		USING 
			(
			   SELECT DISTINCT Source.PROPOSAL_ID, 
                               Source.PERSON_ID,
                               'Y' AS Of_DMS_Interest
			   FROM dbo.V_EUS_Import_Proposal_Participants Source
			        INNER JOIN ( SELECT PROPOSAL_ID
			                     FROM T_EUS_Proposals
			                     WHERE State_ID IN (1,2) 
			                   ) DmsEUSProposals
			          ON Source.PROPOSAL_ID = DmsEUSProposals.PROPOSAL_ID
			) AS Source (Proposal_ID, Person_ID, Of_DMS_Interest)
		ON (target.Proposal_ID = source.Proposal_ID AND
		    target.Person_ID = source.Person_ID)
		WHEN MATCHED AND IsNull(target.State_ID, 0) NOT IN (1, 4)
			THEN UPDATE 
				Set	State_ID = 1,
					Last_Affected = GetDate()
		WHEN Not Matched THEN
			INSERT (Proposal_ID, Person_ID, Of_DMS_Interest, State_ID, Last_Affected)
			VALUES (source.Proposal_ID, source.PERSON_ID, source.Of_DMS_Interest, 1, GetDate())
		WHEN NOT MATCHED BY SOURCE AND IsNull(State_ID, 0) NOT IN (2,4) THEN
			-- User/proposal mapping is defined in T_EUS_Proposal_Users but not in V_EUS_Import_Proposal_Participants
			-- Flag entry to indicate we need to possibly update the state for this row to 5 (checked later in the procedure)
			UPDATE SET State_ID=3, Last_Affected = GetDate()
		OUTPUT $action INTO #Tmp_UpdateSummary
		;
	
		if @myError <> 0
		begin
			set @message = 'Error merging V_EUS_Import_Proposal_Participants with T_EUS_Proposal_Users (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateEUSUsersFromEUSImports'
			goto Done
		end


		set @MergeUpdateCount = 0
		set @MergeInsertCount = 0
		set @MergeDeleteCount = 0

		SELECT @MergeInsertCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'INSERT'

		SELECT @MergeUpdateCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'UPDATE'

		SELECT @MergeDeleteCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'DELETE'
		
		
		---------------------------------------------------
		-- Update rows in T_EUS_Proposal_Users where State_ID is 3=Unknown
		-- but the associated proposal has state of 3=Inactive
		---------------------------------------------------
		
		UPDATE T_EUS_Proposal_Users
		SET State_ID = 2
		FROM T_EUS_Proposal_Users
		     INNER JOIN T_EUS_Proposals
		       ON T_EUS_Proposal_Users.Proposal_ID = T_EUS_Proposals.PROPOSAL_ID
		WHERE T_EUS_Proposal_Users.State_ID = 3 AND
		      T_EUS_Proposals.State_ID IN (3,4)
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		
		---------------------------------------------------
		-- Update rows in T_EUS_Proposal_Users that still have State_ID is 3=Unknown
		-- but the associated proposal has state 2=Active
		---------------------------------------------------

		UPDATE T_EUS_Proposal_Users
		SET State_ID = 5
		FROM T_EUS_Proposal_Users
		     INNER JOIN T_EUS_Proposals
		       ON T_EUS_Proposal_Users.Proposal_ID = T_EUS_Proposals.PROPOSAL_ID
		WHERE T_EUS_Proposal_Users.State_ID = 3 AND
		      T_EUS_Proposals.State_ID = 2
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		
		If @MergeUpdateCount > 0 OR @MergeInsertCount > 0 OR @MergeDeleteCount > 0
		Begin
			Set @message = 'Updated T_EUS_Proposal_Users: ' + Convert(varchar(12), @MergeInsertCount) + ' added; ' + Convert(varchar(12), @MergeUpdateCount) + ' updated'
			
			If @MergeDeleteCount > 0
				Set @message = @message + '; ' + Convert(varchar(12), @MergeDeleteCount) + ' deleted'
				
			Exec PostLogEntry 'Normal', @message, 'UpdateEUSUsersFromEUSImports'
			Set @message = ''
		End
		
		
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateEUSUsersFromEUSImports')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch

	---------------------------------------------------
	-- Done
	---------------------------------------------------
			
Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'UpdateEUSUsersFromEUSImports', @UsageMessage


	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DDL_Viewer] AS [dbo]
GO
GRANT ALTER ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsersFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO
