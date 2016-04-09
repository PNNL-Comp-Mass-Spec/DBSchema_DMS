/****** Object:  UserDefinedFunction [dbo].[MakeTableFromListDelim] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.MakeTableFromListDelim
/****************************************************
**
**	Desc: 
**  Returns a table filled with the contents of a delimited list
**
**	Return values: 
**
**	Parameters:
**	
**
**		Auth: grk
**		Date: 1/8/2007
**    
**		03/05/2008 jds - added the line to convert null list to empty string if value is null 
**		09/16/2009 mem - Expanded @list to varchar(max) 
**		04/07/2016 mem - Update to use udfParseDelimitedList
**    
*****************************************************/
(
@list varchar(max),
@delimiter char(1) = ','
)
RETURNS @theTable TABLE
   (
    Item varchar(128)
   )
AS
BEGIN
		
		INSERT INTO @theTable
			(Item)
		SELECT Value
		FROM dbo.udfParseDelimitedList(@list, @delimiter)
		RETURN
END

GO
