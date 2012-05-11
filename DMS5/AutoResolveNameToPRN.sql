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
**    
*****************************************************/
(
	@NameSearchSpec varchar(64),				-- Used to search U_Name in T_Users; use % for a wildcard; note that a % will be appended to @NameSearchSpec if it doesn't end in one
	@MatchCount int=0 output,					-- Number of entries in T_Users that match @NameSearchSpec
	@MatchingPRN varchar(64)='' output,			-- If @NameSearchSpec > 0, then the PRN of the first match in T_Users
	@MatchingUserID int=0 output				-- If @NameSearchSpec > 0, then the ID of the first match in T_Users
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
		WHERE (U_Name LIKE @NameSearchSpec)
		ORDER BY ID
		
	End
		
	return @myError

GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveNameToPRN] TO [Limited_Table_Write] AS [dbo]
GO
