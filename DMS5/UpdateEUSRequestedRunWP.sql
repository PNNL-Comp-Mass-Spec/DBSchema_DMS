/****** Object:  StoredProcedure [dbo].[UpdateEUSRequestedRunWP] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateEUSRequestedRunWP
/****************************************************
**
**	Desc: 
**		Updates the work package for requested runs
**		from EUS projects by looking for other requested runs
**		from the same project that have a work package
**
**		Changes will be logged to T_Log_Entries
**
**	Return values: 0: success, otherwise, error code
**
**	Auth: 	mem
**	Date: 	12/18/2015 mem - Initial version
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@SearchWindowDays int = 30,	
	@InfoOnly tinyint = 0
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Declare @message varchar(512) = ''

	Begin TRY 

		----------------------------------------------------------
		-- Validate the inputs
		----------------------------------------------------------

		Set @SearchWindowDays = IsNull(@SearchWindowDays, 30)		
		Set @InfoOnly = IsNull(@InfoOnly, 0)

		If @SearchWindowDays < 0
			Set @SearchWindowDays = Abs(@SearchWindowDays)
			
		If @SearchWindowDays < 1
			Set @SearchWindowDays = 1
		
		If @SearchWindowDays > 120
			set @SearchWindowDays = 120
			
		----------------------------------------------------------
		-- Create some temporary tables
		----------------------------------------------------------
		--
		CREATE TABLE #Tmp_WPInfo (
			Proposal_ID varchar(12) not null,
			WorkPackage varchar(50) not null,
		    Requests int not null,
		    UsageRank int not null
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_WPInfo ON #Tmp_WPInfo (Proposal_ID, WorkPackage)

		CREATE TABLE #Tmp_ReqRunsToUpdate (
			Entry_ID int identity(1,1) not null,
			ID int not null,
			Proposal_ID varchar(12) not null,
			WorkPackage varchar(50) not null,
			Message varchar(2048) null
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_ReqRunsToUpdate ON #Tmp_ReqRunsToUpdate (ID)
		
		----------------------------------------------------------
		-- Find the Proposal_ID to WorkPackage mapping for Requested Runs that have a WP defined
		----------------------------------------------------------
		--		
		INSERT INTO #Tmp_WPInfo( Proposal_ID,
		                         WorkPackage,
		                         Requests,
		                         UsageRank )
		SELECT Proposal_ID,
		       RDS_WorkPackage,
		       Requests,
		       Row_Number() OVER ( Partition BY proposal_id ORDER BY Requests DESC ) AS UsageRank
		FROM ( SELECT EUSPro.Proposal_ID,
		              RR.RDS_WorkPackage,
		              COUNT(*) AS Requests
		       FROM T_Dataset DS
		            INNER JOIN T_Requested_Run RR
		              ON DS.Dataset_ID = RR.DatasetID
		            INNER JOIN T_EUS_UsageType EUSUsage
		              ON RR.RDS_EUS_UsageType = EUSUsage.ID
		            INNER JOIN T_EUS_Proposals EUSPro
		              ON RR.RDS_EUS_Proposal_ID = EUSPro.Proposal_ID
		       WHERE (DS.DS_created BETWEEN DATEADD(DAY, -@SearchWindowDays, GETDATE()) AND GETDATE()) AND
		             (EUSPro.Proposal_Type NOT IN ('PROPRIETARY', 'RESOURCE_OWNER', 'PROPRIETARY_PUBLIC')) AND
		             (ISNULL(RR.RDS_WorkPackage, '') NOT IN ('none', 'na', 'n/a', ''))
		       GROUP BY EUSPro.Proposal_ID, RDS_WorkPackage 
		       ) LookupQ

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @InfoOnly <> 0
		Begin
			SELECT * 
			FROM #Tmp_WPInfo
			ORDER BY Proposal_ID, UsageRank Desc
		End
		
		-- Find requested runs to update
		--
		INSERT INTO #Tmp_ReqRunsToUpdate( ID,
		                                  Proposal_ID,
		                                  WorkPackage )
		SELECT RR.ID,
		       EUSPro.Proposal_ID,
		       RR.RDS_WorkPackage
		FROM T_Dataset DS
		     INNER JOIN T_Requested_Run RR
		       ON DS.Dataset_ID = RR.DatasetID
		     INNER JOIN T_EUS_UsageType EUSUsage
		       ON RR.RDS_EUS_UsageType = EUSUsage.ID
		     INNER JOIN T_EUS_Proposals EUSPro
		       ON RR.RDS_EUS_Proposal_ID = EUSPro.Proposal_ID
		     INNER JOIN #Tmp_WPInfo
		       ON EUSPro.Proposal_ID = #Tmp_WPInfo.Proposal_ID And UsageRank = 1
		WHERE (DS.DS_created BETWEEN DATEADD(DAY, -@SearchWindowDays, GETDATE()) AND GETDATE()) AND
		      (EUSPro.Proposal_Type NOT IN ('PROPRIETARY', 'RESOURCE_OWNER', 'PROPRIETARY_PUBLIC')) AND
		      (ISNULL(RR.RDS_WorkPackage, '') IN ('none', 'na', 'n/a', ''))
		GROUP BY RR.ID,
		       EUSPro.Proposal_ID,
		       RR.RDS_WorkPackage
		ORDER BY EUSPro.Proposal_ID, RR.ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		----------------------------------------------------------
		-- These tables are used to generate the log message 
		-- that describes the requested runs that will be updated
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
		
		----------------------------------------------------------
		-- Loop through the entries in #Tmp_ReqRunsToUpdate
		----------------------------------------------------------
		
		Declare @EntryID int = 0
		Declare @ProposalID varchar(12) = ''
		Declare @RRStart int
		
		Declare @newWP varchar(50)
		Declare @ValueList varchar(max)
		Declare @LogMessage varchar(2048)		

		While @EntryID >= 0
		Begin -- <a>
		
			SELECT TOP 1 @EntryID = Entry_ID,
			             @ProposalID = Proposal_ID,
			             @RRStart = ID
			FROM #Tmp_ReqRunsToUpdate
			Where Entry_ID > @EntryID And Proposal_ID <> @ProposalID
			ORDER BY Entry_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
			Begin
				Set @EntryID = -1
			End
			Else
			Begin -- <b>
			
				SELECT @newWP = WorkPackage
				FROM #Tmp_WPInfo
				WHERE Proposal_ID = @ProposalID AND UsageRank = 1
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			
				If @myRowCount <> 1
				Begin
					Set @LogMessage = 'Logic error; did not find a single match for proposal ' + @ProposalID + ' in #Tmp_WPInfo'
					exec PostLogEntry 'Error', @LogMessage , 'UpdateEUSRequestedRunWP'
					Goto Done
				End
										
				truncate table #Tmp_ValuesByCategory
				truncate table #Tmp_Condensed_Data
				
				INSERT INTO #Tmp_ValuesByCategory (Category, Value)
				SELECT 'RR', ID
				FROM #Tmp_ReqRunsToUpdate
				WHERE Proposal_ID = @ProposalID
				ORDER BY ID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @InfoOnly <> 0
					Set @LogMessage = 'Updating WP to ' + @newWP + ' for requested'
				Else
					Set @LogMessage = 'Updated WP to ' + @newWP + ' for requested'
					
				If @myRowCount = 1
				Begin
					Set @LogMessage = @LogMessage + ' run ' + Cast(@RRStart as varchar(12))
				End
				Else
				Begin
					Exec CondenseIntegerListToRanges @debugMode=0
					
					Set @ValueList = ''
					
					SELECT TOP 1 @ValueList = ValueList
					FROM #Tmp_Condensed_Data

					Set @LogMessage = @LogMessage + ' runs ' + @ValueList
				End

				UPDATE #Tmp_ReqRunsToUpdate
				SET Message = @LogMessage
				WHERE Proposal_ID = @ProposalID
								
				If @InfoOnly = 0
				Begin -- <c>
					UPDATE T_Requested_Run
					SET RDS_WorkPackage = @newWP
					FROM T_Requested_Run Target
					     INNER JOIN #Tmp_ReqRunsToUpdate Src
					       ON Target.ID = Src.ID AND
					          Src.Proposal_ID = @ProposalID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
									
					Exec PostLogEntry 'Normal', @LogMessage, 'UpdateEUSRequestedRunWP'
				End -- </c>
				
			End -- </b>
		End -- </a>
		
		If @InfoOnly <> 0
		Begin
			----------------------------------------------------------
			-- Preview what would be updated
			----------------------------------------------------------
			--						
			If Exists (Select * from #Tmp_ReqRunsToUpdate)
				SELECT Src.*
				FROM #Tmp_ReqRunsToUpdate Src
				ORDER BY Src.Proposal_ID, Src.ID	
			Else
				SELECT 'No candidate requested runs were found to update' AS Message
			
		End
		

	End TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Print @message
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	End CATCH

Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSRequestedRunWP] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSRequestedRunWP] TO [PNL\D3M580] AS [dbo]
GO
