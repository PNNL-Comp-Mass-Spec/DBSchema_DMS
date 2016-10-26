/****** Object:  UserDefinedFunction [dbo].[RemoveFromString] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.RemoveFromString
/****************************************************
**
**	Desc:	Removes the specified text from the parent string, including
**			removing any comma or semicolon delimiter that precedes the text
**
**	Returns the updated string
**
**		Auth:	mem
**		Date:	10/25/2016 mem - Initial version
**
*****************************************************/
(
	@text varchar(2048),				-- Text to search
	@textToRemove varchar(1024)			-- Text to remove
)
	RETURNS varchar(2048)
AS
Begin
 
	Declare @CharLoc int
	Declare @iteration tinyint = 0
	Declare @textToFind varchar(1030)
	
	If IsNull(@text, '') = ''
		Set @text = ''

	If IsNull(@textToRemove, '') <> ''
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
	
	Return @text 
End


GO
