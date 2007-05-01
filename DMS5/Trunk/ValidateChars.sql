/****** Object:  UserDefinedFunction [dbo].[ValidateChars] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.ValidateChars
/****************************************************
**
**	Desc: 
**		validates that string only contains characters
**      from valid set
**
**		Auth: grk
**		Date: 04/30/2007 Ticket #450
**    
*****************************************************/
(
	@string char(512),
	@validCh char(128) = ''
)
RETURNS varchar(256)
AS
BEGIN
	IF @validCh = ''
		SET @validCh = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'

	DECLARE @asc int, @ch char(1)
	DECLARE @position int, @numCh int
	DECLARE @badCh varchar(256)
	-- 
	SET @position = 1
	SET @numCh = len(@string)
	SET @badCh = ''
	WHILE @position <= @numCh
		BEGIN
			set @ch = SUBSTRING(@string, @position, 1)
			if CHARINDEX(@ch, @validCh) = 0
				SET @badCh = @badCh + @ch
			SET @position = @position + 1
		END
	RETURN @badCh
END

GO
