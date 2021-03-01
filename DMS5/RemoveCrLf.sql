/****** Object:  UserDefinedFunction [dbo].[RemoveCrLf] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[RemoveCrLf]
/****************************************************
**
**	Desc:	Removes carriage returns and line feeds from the text
**          After removing, also trims leading or trailing commas or semicolons
**
**	Returns the updated string
**
**	Auth:	mem
**	Date:	02/25/2021 mem - Initial version
**
*****************************************************/
(
	@text varchar(2048)				-- Text to search
)
	RETURNS varchar(2048)
AS
Begin
 
    Set @text = REPLACE(@text, CHAR(13) + CHAR(10), '; ')
    Set @text = REPLACE(@text, CHAR(10), '; ')
    Set @text = REPLACE(@text, CHAR(13), '; ')
		
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
GRANT VIEW DEFINITION ON [dbo].[RemoveCrLf] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RemoveCrLf] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RemoveCrLf] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RemoveCrLf] TO [Limited_Table_Write] AS [dbo]
GO
