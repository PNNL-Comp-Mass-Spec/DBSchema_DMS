/****** Object:  StoredProcedure [dbo].[AutoResolveNameToPRN] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.AutoResolveNameToPRN
/****************************************************
** 
**	Desc:	Looks for entries in T_Users that match @NameSearchSpec
**			Updates @MatchCount with the number of matching entries
**
**			If one more more entries is found, then updates @MatchingPRN and @MatchingUserID for the first match
**		
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	02/07/2010
**			01/20/2017 mem - Now checking for names of the form "Last, First (D3P704)" or "Last, First Middle (D3P704)" and auto-fixing those
**    
*****************************************************/
(
	@NameSearchSpec varchar(64),				-- Used to search U_Name in T_Users; use % for a wildcard; note that a % will be appended to @NameSearchSpec if it doesn't end in one
	@MatchCount int=0 output,					-- Number of entries in T_Users that match @NameSearchSpec
	@MatchingPRN varchar(64)='' output,			-- If @NameSearchSpec > 0, then the PRN of the first match in T_Users
	@MatchingUserID int=0 output				-- If @NameSearchSpec > 0, then the ID of the first match in T_Users
)
As
	Set nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Set @MatchCount = 0

	If @NameSearchSpec Like '%,%(%)'
	Begin
		-- Name is of the form  "Last, First (D3P704)" or "Last, First Middle (D3P704)"
		-- Extract D3P704
		
		Declare @charIndexStart int = PatIndex('%(%)%', @NameSearchSpec)
		Declare @charIndexEnd int = CharIndex(')', @NameSearchSpec, @charIndexStart)

		If @charIndexStart > 0
		Begin
			Set @NameSearchSpec = Substring(@NameSearchSpec, @charIndexStart+1, @charIndexEnd-@charIndexStart-1)
			
			SELECT @MatchingPRN = U_PRN,
			       @MatchingUserID = ID
			FROM T_Users
			WHERE U_PRN = @NameSearchSpec
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount > 0
			Begin
				Set @MatchCount = 1
				Goto Done
			End
		End
	End
	
	If Not @NameSearchSpec LIKE '%[%]'
	Begin
		Set @NameSearchSpec = @NameSearchSpec + '%'
	End
	
	SELECT @MatchCount = COUNT(*)
	FROM T_Users
	WHERE (U_Name LIKE @NameSearchSpec)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError = 0 And @MatchCount > 0
	Begin
		-- Update @MatchingPRN and @MatchingUserID
		SELECT TOP 1 @MatchingPRN = U_PRN,
		             @MatchingUserID = ID
		FROM T_Users
		WHERE U_Name LIKE @NameSearchSpec
		ORDER BY ID
		
	End

Done:		
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveNameToPRN] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveNameToPRN] TO [Limited_Table_Write] AS [dbo]
GO
