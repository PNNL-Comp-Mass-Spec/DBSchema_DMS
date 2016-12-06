/****** Object:  StoredProcedure [dbo].[AutoResolveOrganismName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.AutoResolveOrganismName
/****************************************************
** 
**	Desc:	Looks for entries in T_Organisms that match @NameSearchSpec
**			First checks OG_name then checks OG_Short_Name
**			Updates @MatchCount with the number of matching entries
**
**			If one more more entries is found, updates @MatchingOrganismName and @MatchingOrganismID for the first match
**		
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	12/02/2016
**    
*****************************************************/
(
	@NameSearchSpec varchar(64),					-- Used to search OG_name and OG_Short_Name in T_Organisms; use % for a wildcard; note that a % will be appended to @NameSearchSpec if it doesn't end in one
	@MatchCount int=0 output,						-- Number of entries in T_Organisms that match @NameSearchSpec
	@MatchingOrganismName varchar(64)='' output,	-- If @NameSearchSpec > 0, then the Organism name of the first match in T_Organisms
	@MatchingOrganismID int=0 output				-- If @NameSearchSpec > 0, then the ID of the first match in T_Organisms
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Set @MatchCount = 0

	If Not @NameSearchSpec LIKE '%[%]'
		Set @NameSearchSpec = @NameSearchSpec + '%'
	
	SELECT @MatchCount = COUNT(*)
	FROM T_Organisms
	WHERE OG_name LIKE @NameSearchSpec
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError = 0 And @MatchCount > 0
	Begin
		-- Update @MatchingOrganismName and @MatchingOrganismID
		--
		SELECT TOP 1 @MatchingOrganismName = OG_name,
		             @MatchingOrganismID = Organism_ID
		FROM T_Organisms
		WHERE OG_name LIKE @NameSearchSpec
		ORDER BY Organism_ID		
	End

	If @myError = 0 And @MatchCount = 0
	Begin
		SELECT @MatchCount = COUNT(*)
		FROM T_Organisms
		WHERE OG_Short_Name LIKE @NameSearchSpec
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myError = 0 And @MatchCount > 0
		Begin
			-- Update @MatchingOrganismName and @MatchingOrganismID
			--
			SELECT TOP 1 @MatchingOrganismName = OG_name,
			             @MatchingOrganismID = Organism_ID
			FROM T_Organisms
			WHERE OG_Short_Name LIKE @NameSearchSpec
			ORDER BY Organism_ID
		End
	End
			
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveOrganismName] TO [DDL_Viewer] AS [dbo]
GO
