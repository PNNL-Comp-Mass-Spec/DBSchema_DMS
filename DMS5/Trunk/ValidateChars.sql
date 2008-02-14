/****** Object:  UserDefinedFunction [dbo].[ValidateChars] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.ValidateChars
/****************************************************
**
**	Desc: 
**		Validates that string only contains characters from valid set
**		Returns the bad characters if any are found
**		If @validCh does not contain a space but @string does, then returns [space]
**       (in addition to any other bad characters)
**
**	Auth:	grk
**	Date:	04/30/2007 grk - Ticket #450
**			02/13/2008 mem - Updated to check for @string containing a space (Ticket #602)
**    
*****************************************************/
(
	@string varchar(512),
	@validCh varchar(128) = ''			-- If default, then checks for letters, numbers, underscore, and dash
)
RETURNS varchar(256)
AS
BEGIN
	IF @validCh = ''
		SET @validCh = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'

	DECLARE @asc int, @ch char(1)
	DECLARE @position int, @numCh int
	DECLARE @badCh varchar(256)

	SET @badCh = ''

	-- See if @validCh contains a space
	If CharIndex(' ', @validCh) = 0
	Begin
		-- Do not allow spaces
		If @string LIKE '%[ ]%'
			Set @badCh = @badCh + '[space]'
	End
		
	-- 
	SET @position = 1
	SET @numCh = len(@string)
	WHILE @position <= @numCh
		BEGIN
			set @ch = SUBSTRING(@string, @position, 1)

			-- Note thate @ch will have a length of 0 if it is a space; spaces are handled above
			If Len(@ch) > 0
			Begin
				If CHARINDEX(@ch, @validCh) = 0
					Set @badCh = @badCh + @ch
			End
				
			SET @position = @position + 1
		END
	RETURN @badCh
END

GO
