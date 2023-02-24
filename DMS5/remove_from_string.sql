/****** Object:  UserDefinedFunction [dbo].[RemoveFromString] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[RemoveFromString]
/****************************************************
**
**	Desc:	Removes the specified text from the parent string, including
**			removing any comma or semicolon delimiter that precedes the text
**
**			If @textToRemove ends in a percent sign (wildcard symbol), this function will also remove text
**			following @textToRemove, continuing to the next delimiter (comma, semicolon, or end of string)
**
**	Returns the updated text
**
**	Auth:	mem
**	Date:	10/25/2016 mem - Initial version
**			08/08/2017 mem - Add support for @textToRemove ending in %
**          06/23/2022 mem - Move logic that handles wildcards (percent signs) outside the while loop
**
*****************************************************/
(
	@text varchar(2048),				-- Text to search
	@textToRemove varchar(1024)			-- Text to remove; may optionally end wit a percent sign
)
	RETURNS varchar(2048)
AS
Begin
 
	Declare @CharLoc int
	Declare @iteration tinyint = 0
	Declare @textToFind varchar(1030)
	
	Declare @matchPos int
	Declare @nextDelimiter int
			
	If IsNull(@text, '') = ''
		Set @text = ''
        
	If Right(@textToRemove, 1) = '%'
	Begin
		Set @matchPos = PatIndex('%' + @textToRemove, @text)
				
		If @matchPos >= 1
		Begin
			Set @nextDelimiter = CharIndex(';', @text, @matchPos + 1)
			If @nextDelimiter = 0
			Begin
				Set @nextDelimiter = CharIndex(',', @text, @matchPos + 1)
			End
					
			If @nextDelimiter > 1
			Begin
				Set @text = 
					Rtrim(Left(@text, @matchPos-1) + 
					LTrim(Substring(@text, @nextDelimiter + 1, Len(@text))))
			End
			Else
			Begin
				Set @text = Rtrim(Left(@text, @matchPos-1))
			End
		End
	End
    Else If IsNull(@textToRemove, '') <> ''
	Begin
		While @iteration <= 4
		Begin
			If @iteration = 0
				Set @textToFind = '; ' + @textToRemove
			If @iteration = 1
				Set @textToFind = ';' + @textToRemove
			If @iteration = 2
				Set @textToFind = ', ' + @textToRemove
			If @iteration = 3
				Set @textToFind = ',' + @textToRemove
			If @iteration = 4
				Set @textToFind = @textToRemove
			
			Set @text = Replace(@text, @textToFind, '')
			Set @iteration = @iteration + 1
		End		
	End
		
	-- Check for leading or trailing whitespace, comma, or semicolon
	Set @text = LTrim(RTrim(@text))
	
	If @text LIKE '%;' Or @text LIKE '%,'
	Begin
		Set @text = RTrim(Left(@text, Len(@text)-1))
	End	
	
	If @text LIKE ';%' Or @text LIKE ',%'
	Begin
		Set @text = LTrim(Substring(@text, 2, Len(@text)-1))
	End	
	
	Return @text 
End


GO
GRANT VIEW DEFINITION ON [dbo].[RemoveFromString] TO [DDL_Viewer] AS [dbo]
GO
