/****** Object:  StoredProcedure [dbo].[AutoDefineSupersededEUSProposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AutoDefineSupersededEUSProposals]
/****************************************************
**
**	Desc:	Looks for proposals in T_EUS_Proposals with the same name
**          Auto populates Proposal_ID_AutoSupersede for superseded proposals (if currently null) 
**
**	Auth:	mem
**	Date:	08/12/2020 mem - Initial Version
**    
*****************************************************/
(
	@infoOnly tinyint = 1
)
AS
	Set NoCount On

	Declare @myRowCount int	= 0
	Declare @myError int = 0
    
    Declare @message varchar(2048)
    Declare @proposalList varchar(2048)

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 0)
		
	---------------------------------------------------
	-- Create a temporary table
	---------------------------------------------------

	CREATE TABLE #Tmp_ProposalsToUpdate
	(
		Proposal_ID varchar(20) NOT NULL,
		Newest_Proposal_ID varchar(20) NOT NULL
	)

	---------------------------------------------------
	-- Find proposals that need to be updated
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ProposalsToUpdate( Proposal_ID, Newest_Proposal_ID )
	SELECT EUP.Proposal_ID,
	       RankQ.Proposal_ID AS Newest_ID
	FROM T_EUS_Proposals EUP
	     INNER JOIN ( SELECT Title,
	                         COUNT(*) AS Entries
	                  FROM T_EUS_Proposals
	                  GROUP BY Title
	                  HAVING (COUNT(*) > 1) ) DuplicateQ
	       ON EUP.Title = DuplicateQ.Title
	     INNER JOIN ( SELECT Title,
	                         Proposal_ID,
	                         ROW_NUMBER() OVER ( PARTITION BY title ORDER BY Proposal_Start_Date DESC ) AS StartRank
	                  FROM T_EUS_Proposals ) RankQ
	       ON EUP.Title = RankQ.Title AND
	          RankQ.StartRank = 1 AND
	          EUP.Proposal_ID <> RankQ.Proposal_ID
	WHERE State_ID <> 5 AND
	      IsNull(EUP.Proposal_ID_AutoSupersede, '') <> RankQ.Proposal_ID AND
	      EUP.Proposal_ID_AutoSupersede IS NULL
	ORDER BY EUP.Proposal_ID
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

    If @infoOnly <> 0
    Begin
	    ---------------------------------------------------
	    -- Preview the updates
	    ---------------------------------------------------
        --
        SELECT EUP.Proposal_ID,
               EUP.Numeric_ID,
               EUP.Title,
               EUP.State_ID,
               EUP.Proposal_Start_Date,
               EUP.Proposal_End_Date,
               EUP.Proposal_ID_AutoSupersede,
               UpdatesQ.Newest_Proposal_ID,
               EUP_Newest.Proposal_Start_Date AS Newest_Proposal_Start_Date,
               EUP_Newest.Proposal_End_Date AS Newest_Proposal_End_Date
        FROM T_EUS_Proposals EUP
             INNER JOIN #Tmp_ProposalsToUpdate UpdatesQ
               ON EUP.Proposal_ID = UpdatesQ.Proposal_ID
             INNER JOIN T_EUS_Proposals EUP_Newest
               ON UpdatesQ.Newest_Proposal_ID = EUP_Newest.Proposal_ID
        ORDER BY EUP.Title
    End
    Else
    Begin
        If NOT Exists (SELECT * FROM #Tmp_ProposalsToUpdate)
        Begin
            Set @message = 'No superseded proposals were found; nothing to do'
        End
        Else
        Begin
	        ---------------------------------------------------
	        -- Construct a list of the proposals IDs being updated
	        ---------------------------------------------------
            --
            Set @proposalList = ''

            SELECT @proposalList = @proposalList + ', ' + Proposal_ID
            FROM #Tmp_ProposalsToUpdate
            ORDER BY Proposal_ID

            -- Trim the leading comma
            If @proposalList LIKE ', %'
                Set @proposalList = SUBSTRING(@proposalList, 3, LEN(@proposalList))

                
	        ---------------------------------------------------
	        -- Populate Proposal_ID_AutoSupersede
	        ---------------------------------------------------
            --
            UPDATE T_EUS_Proposals
            SET Proposal_ID_AutoSupersede = UpdatesQ.Newest_Proposal_ID
            FROM T_EUS_Proposals EUP
                 INNER JOIN #Tmp_ProposalsToUpdate UpdatesQ
                   ON EUP.Proposal_ID = UpdatesQ.Proposal_ID
		    --
	        SELECT @myRowCount = @@rowcount, @myError = @@error

	        Set @message = 'Auto-set Proposal_ID_AutoSupersede for ' + CAST(@myRowCount AS VARCHAR(12)) + ' proposal(s) in T_EUS_Proposals: ' + @proposalList

		    EXEC PostLogEntry 'Normal', @message, 'AutoDefineSupersededEUSProposals'
        End

        Print @message
    End
	
	return 0

GO
