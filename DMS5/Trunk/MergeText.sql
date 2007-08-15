/****** Object:  UserDefinedFunction [dbo].[MergeText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.MergeText
/****************************************************	
**	Merges together the text in two variables
**  However, if the same text is present in each,
**  then it will be skipped
**
**	Auth:	mem
**	Date:	08/03/2007
**  
****************************************************/
(
	@Text1 varchar(2048),
	@Text2 varchar(2048)
)
RETURNS varchar(8000)
AS
BEGIN
	Declare @CombinedText varchar(8000)

	Set @CombinedText = LTrim(RTrim(IsNull(@Text1, '')))
	Set @Text2 = LTrim(RTrim(IsNull(@Text2, '')))
	
	If Len(@Text2) > 0
	Begin
		If @CombinedText <> @Text2
		Begin
			If Len(@CombinedText) > 0
				Set @CombinedText = @CombinedText + '; ' + @Text2
			Else
				Set @CombinedText = @Text2				
		End
	End
		
	RETURN  @CombinedText
END


GO
GRANT EXECUTE ON [dbo].[MergeText] TO [public]
GO
