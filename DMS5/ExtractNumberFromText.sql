/****** Object:  UserDefinedFunction [dbo].[ExtractNumberFromText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.ExtractNumberFromText
/****************************************************
**
**	Desc: 
**		Examines the text provided to return the next 
**      integer value present, starting at @StartLoc
**
**	Return values: number found, or 0 if no number found
**
**	Parameters:	@SearchText - the text to search for a number
**				@StartLoc - the position to start searching at
**
**	See also UDF ExtractInteger
**	That UDF does not have a @StartLoc parameter, and it returns null if a number is not found
**
**	Auth:	mem
**	Date:	07/31/2007
**			04/26/2016 mem - Check for negative numbers
**    
*****************************************************/
(
	@SearchText varchar(4000),
	@StartLoc int
)
RETURNS int
AS
BEGIN
	declare @Value int
	set @Value = 0

	declare @loc int
	declare @TextLength int
	Set @TextLength = Len(@SearchText)
	
	If IsNull(@StartLoc, 0) > 1
	Begin
		Set @SearchText = Substring(@SearchText, @StartLoc, @TextLength)
		Set @TextLength = Len(@SearchText)
	End
	
	-- Find the first number in @SearchText, starting at @StartLoc
	Set @loc = PatIndex('%[0-9]%', @SearchText)
	
	If @loc > 0
	Begin
		-- Number found
		-- Step through @SearchText to find the contiguous numbers
		
		Declare @NextChar char
		Declare @ValueText varchar(4000)
		Set @ValueText = Substring(@SearchText, @loc, 1)
		
		-- Check for negative numbers
		If @loc > 1 And SubString(@SearchText, @loc-1, 1) = '-'
			Set @ValueText = '-' + @ValueText
			
		While @Loc > 0 And @Loc < @TextLength
		Begin
			Set @NextChar = Substring(@SearchText, @Loc+1, 1)
			If @NextChar LIKE '[0-9]'
			Begin
				Set @ValueText = @ValueText + @NextChar
				Set @Loc = @Loc + 1
			End
			Else
				Set @Loc = 0
		End
		
		Set @Value = Convert(int, @ValueText)
	End

	Return @Value
END


GO
GRANT EXECUTE ON [dbo].[ExtractNumberFromText] TO [public] AS [dbo]
GO
