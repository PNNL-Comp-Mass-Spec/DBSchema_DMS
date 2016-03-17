/****** Object:  StoredProcedure [dbo].[GetWPforEUSProposal] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetWPforEUSProposal
/****************************************************
**
**	Desc:	Determines best work package to use for a given EUS user proposal
**			Output parameter @workPackage will be 'none' if no match is found
**
**	Returns: The storage path ID; 0 if an error
**
**	Auth:	mem
**	Date:	01/29/2016 mem - Initial Version
**    
*****************************************************/
(
	@eusProposalID varchar(10),
	@workPackage varchar(50) = '' output,
	@monthsSearched int = 0 output			-- Number of months back that this procedure searched to find a work package for @eusProposalID; 0 if no match
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

	Set @eusProposalID = IsNull(@eusProposalID, '')
	
	Set @workPackage = 'none'
	Set @monthsSearched = 0
	
	-----------------------------------------
	-- Find the most commonly used work package for the EUS proposal
	-- First look for use in the last 2 months
	-- If no match, try the last 4 months, then 8 months, then 16 months, then all records
	-----------------------------------------
	--

	If Exists (SELECT * FROM T_EUS_Proposals WHERE (Proposal_ID = @eusProposalID))
	Begin
		
		Declare @monthThreshold int = 2
		Declare @workPackageNew varchar(50) = ''
		Declare @continue tinyint = 1
		Declare @AllMonthsCount int = DateDiff(month, 0, GetDate())

		While @continue = 1
		Begin
				
			SELECT TOP 1 @workPackageNew = RDS_WorkPackage
			FROM T_Requested_Run
			WHERE RDS_EUS_Proposal_ID = @eusProposalID AND 
			      RDS_WorkPackage <> 'none' AND 
			      Entered >= DATEADD(month, -@monthThreshold, GETDATE())
			GROUP BY RDS_WorkPackage
			ORDER BY COUNT(*) DESC
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
			
			If @myRowCount > 0
			Begin
				Set @continue = 0
			End
			Else
			Begin
				If @monthThreshold >= @AllMonthsCount
				Begin
					Set @continue = 0
				End
				Else
				Begin
					Set @monthThreshold = @monthThreshold * 2
					If @monthThreshold > 16
						Set @monthThreshold = @AllMonthsCount
				End
			End
		End

		Set @workPackageNew = IsNull(@workPackageNew, '')
		If @workPackageNew Not In ('', 'none', 'na')
		Begin
			Set @workPackage = @workPackageNew
			Set @monthsSearched = @monthThreshold
		End

	End

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[GetWPforEUSProposal] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetWPforEUSProposal] TO [PNL\D3M580] AS [dbo]
GO
