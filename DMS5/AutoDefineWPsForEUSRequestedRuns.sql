/****** Object:  StoredProcedure [dbo].[AutoDefineWPsForEUSRequestedRuns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AutoDefineWPsForEUSRequestedRuns
/****************************************************
**
**	Desc:	Looks for completed requested runs that have 
**			an EUS proposal but for which the work package is 'none'
**
**			Looks for other uses of that EUS proposal that have
**			a valid work package. If found, changes the WP
**			from 'none' to the new work package
**
**			Preference is given to recently used work packages
**
**	Returns: The storage path ID; 0 if an error
**
**	Auth:	mem
**	Date:	01/29/2016 mem - Initial Version
**    
*****************************************************/
(
	@mostRecentMonths int = 12,
	@infoOnly tinyint = 1
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @mostRecentMonths = IsNull(@mostRecentMonths, 12)
	Set @infoOnly = IsNull(@infoOnly, 0)

	If @mostRecentMonths < 1
		Set @mostRecentMonths = 1
		
	---------------------------------------------------
	-- Create a temporary table
	---------------------------------------------------

	CREATE TABLE #Tmp_ProposalsToCheck
	(
		Entry_ID int Identity(1,1) NOT NULL,
		EUSProposal varchar(20) NOT NULL,
		BestWorkPackage varchar(50) NULL,
		MonthsSearched int NULL
	)

	CREATE CLUSTERED INDEX #IX_Tmp_ProposalsToCheck ON #Tmp_ProposalsToCheck (Entry_ID)

	---------------------------------------------------
	-- Find proposals with a requested run within the 
	-- last @mostRecentMonths and a work package of "none"
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ProposalsToCheck( EUSProposal )
	SELECT P.Proposal_ID
	FROM T_EUS_Proposals P
	     INNER JOIN T_Requested_Run RR
	       ON P.Proposal_ID = RR.RDS_EUS_Proposal_ID
	WHERE Not P.Title Like '%P41%' AND 
	      Not P.Title Like '%NCRR%' AND
	      Not RR.RDS_Status = 'Active' AND
	      RR.RDS_WorkPackage = 'none' AND
	      RR.Entered >= DateAdd(month, -@mostRecentMonths, GetDate())
	GROUP BY P.Proposal_ID
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

	---------------------------------------------------
	-- Process each proposal
	---------------------------------------------------
	--

	Declare @EntryID int = 0
	Declare @EUSProposal varchar(20)
	Declare @continue tinyint= 1
	Declare @workPackage varchar(12) 
	Declare @monthsSearched int

	While @Continue = 1
	Begin
	
		SELECT TOP 1 @EntryID = Entry_ID,
		             @EUSProposal = EUSProposal
		FROM #Tmp_ProposalsToCheck
		WHERE Entry_ID > @EntryID
		ORDER BY Entry_ID

		If @@rowcount = 0
			SET @continue= 0
		ELSE
		Begin
		
			exec GetWPforEUSProposal @EUSProposal, @workPackage output, @monthsSearched output

			If @workPackage <> 'none'
			Begin
				UPDATE #Tmp_ProposalsToCheck
				SET BestWorkPackage = @workPackage,
				    MonthsSearched = @monthsSearched
				WHERE EUSProposal = @EUSProposal
			End
		End
	END

	---------------------------------------------------
	-- Populate a new temporary table with the requested runs to update
	---------------------------------------------------

	CREATE TABLE #Tmp_RequestedRunsToUpdate
	(
		EUSProposal varchar(20) NOT NULL,
		WorkPackage varchar(50) NOT NULL,
		RequestedRunID int not null
	)

	CREATE CLUSTERED INDEX #IX_Tmp_RequestedRunsToUpdate ON #Tmp_RequestedRunsToUpdate (EUSProposal, RequestedRunID)

	INSERT INTO #Tmp_RequestedRunsToUpdate( EUSProposal,
	                                        WorkPackage,
	                                        RequestedRunID )
	SELECT C.EUSProposal,
	       C.BestWorkPackage,
	       RR.ID
	FROM #Tmp_ProposalsToCheck C
	     INNER JOIN T_Requested_Run RR
	       ON RR.RDS_EUS_Proposal_ID = C.EUSProposal AND
	          (RR.RDS_created >= DateAdd(MONTH, - C.MonthsSearched, GetDate()) OR
	           RR.RDS_created >= DateAdd(MONTH, - @mostRecentMonths, GetDate()))
	WHERE C.MonthsSearched < @mostRecentMonths * 2 AND
	      RR.RDS_WorkPackage = 'none' AND
	      Not RR.RDS_Status = 'Active'
	ORDER BY C.EUSProposal

	If @infoOnly <> 0
	Begin
		---------------------------------------------------
		-- Summarize the updates
		---------------------------------------------------

		SELECT C.Entry_ID,
		       C.EUSProposal,
		       C.BestWorkPackage,
		       C.MonthsSearched,
		       COUNT(*) AS RequestedRuns,
		       SUM(CASE WHEN FilterQ.RDS_WorkPackage = 'none' THEN 1 ELSE 0 END) AS RequestsToUpdate,
		       P.Title
		FROM #Tmp_ProposalsToCheck C
		     INNER JOIN ( SELECT ID,
		                         RDS_Name,
		                         RDS_created,
		                         RDS_EUS_Proposal_ID,
		                         RDS_WorkPackage
		                  FROM T_Requested_Run RR
		                  WHERE ID IN ( SELECT RequestedRunID FROM #Tmp_RequestedRunsToUpdate ) OR
		                        (RDS_EUS_Proposal_ID IN ( SELECT EUSProposal FROM #Tmp_RequestedRunsToUpdate ) AND
		                         RR.RDS_created >= DateAdd(MONTH, - @mostRecentMonths, GetDate())
		                        ) 
		                ) FilterQ
		       ON C.EUSProposal = FilterQ.RDS_EUS_Proposal_ID
		       INNER JOIN T_EUS_Proposals P ON P.Proposal_ID = C.EUSProposal
		GROUP BY C.Entry_ID, C.EUSProposal, C.BestWorkPackage, C.MonthsSearched, P.Title
		ORDER BY SUM(CASE WHEN FilterQ.RDS_WorkPackage = 'none' THEN 1 ELSE 0 END) desc


		---------------------------------------------------
		-- Show details of the requested runs associated with the EUS Proposals that we will be updating
		-- This list includes both requested runs with a valid work package, and runs with 'none'
		---------------------------------------------------

		SELECT C.*,
		       FilterQ.RDS_Name,
		       FilterQ.RDS_created,
		       FilterQ.ID AS RequestedRunID,
		       CASE
		           WHEN FilterQ.RDS_WorkPackage = 'none' THEN 'none --> ' + C.BestWorkPackage
		           ELSE FilterQ.RDS_WorkPackage
		       END AS RDS_WorkPackage
		FROM #Tmp_ProposalsToCheck C
		     INNER JOIN ( SELECT ID,
		                         RDS_Name,
		                         RDS_created,
		                         RDS_EUS_Proposal_ID,
		                         RDS_WorkPackage
		                  FROM T_Requested_Run RR
		                  WHERE ID IN ( SELECT RequestedRunID FROM #Tmp_RequestedRunsToUpdate ) OR
		                        (RDS_EUS_Proposal_ID IN ( SELECT EUSProposal FROM #Tmp_RequestedRunsToUpdate ) AND
		                         RR.RDS_created >= DateAdd(MONTH, - @mostRecentMonths, GetDate())
		                        ) 
		                ) FilterQ
		       ON C.EUSProposal = FilterQ.RDS_EUS_Proposal_ID		       
		ORDER BY C.EUSProposal, RDS_Name

	End	

	---------------------------------------------------
	-- Apply or preview the updates
	---------------------------------------------------
		
	Declare @message varchar(128)
	Declare @requestedRunsToUpdate int
	Set @EUSProposal = ''
	Set @Continue = 1
	
	While @Continue = 1
	Begin
	
		SELECT TOP 1 @EUSProposal = EUSProposal,
		             @workPackage = WorkPackage,
		             @requestedRunsToUpdate = Count(*)
		FROM #Tmp_RequestedRunsToUpdate
		WHERE EUSProposal > @EUSProposal
		GROUP BY EUSProposal, WorkPackage
		ORDER BY EUSProposal

		If @@rowcount = 0
			Set @continue= 0
		Else
		Begin
		
			Set @message = 'Changed the work package from none to ' + @workPackage + ' for ' + Cast(@requestedRunsToUpdate as varchar(12)) + ' requested ' + dbo.CheckPlural(@requestedRunsToUpdate, 'run', 'runs') + ' with EUS Proposal ' + @EUSProposal
		
			If @InfoOnly <> 0
				PRINT @message	
			Else
			Begin
			
				UPDATE T_Requested_Run
				SET RDS_WorkPackage = @workPackage
				FROM T_Requested_Run RR
				     INNER JOIN #Tmp_RequestedRunsToUpdate U
				       ON RR.ID = U.RequestedRunID
				WHERE U.EUSProposal = @EUSProposal

				EXEC PostLogEntry 'Normal', @message, 'AutoDefineWPsForEUSRequestedRuns'

			End
			
		End
	End

	DROP TABLE #Tmp_ProposalsToCheck
	DROP TABLE #Tmp_RequestedRunsToUpdate
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AutoDefineWPsForEUSRequestedRuns] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AutoDefineWPsForEUSRequestedRuns] TO [PNL\D3M580] AS [dbo]
GO
