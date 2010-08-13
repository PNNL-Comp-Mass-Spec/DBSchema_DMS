/****** Object:  UserDefinedFunction [dbo].[AppendToText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AppendToText]
/****************************************************
**
**	Desc:	Appends a new string to an existing string, using the specified delimiter
**			If @AddDuplicateText = 0, then checks first to make sure the comment doesn't already contain the new text
**
**	Returns the updated comment
**
**		Auth:	mem
**		Date:	05/12/2010 mem - Initial version
**
*****************************************************/
(
	@Text varchar(1024), 
	@AddnlText varchar(1024),
	@AddDuplicateText tinyint = 0,
	@Delimiter varchar(10) = '; '
)
	RETURNS varchar(1024)
AS
Begin
 
	Declare @CharLoc int
	
	If IsNull(@Text, '') = ''
		Set @Text = ''

	If IsNull(@AddnlText, '') <> ''
	Begin
		Set @CharLoc = 0
		Set @CharLoc = CharIndex(@AddnlText, @Text)
		
		If @CharLoc = 0 Or @AddDuplicateText <> 0
		Begin
			If @Text = ''
				Set @Text = @AddnlText
			Else
				Set @Text = @Text + @Delimiter + @AddnlText
		End
	End
	
	Return @Text 
End


GO
