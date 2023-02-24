/****** Object:  UserDefinedFunction [dbo].[MakeTableFromList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.MakeTableFromList
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
**	Auth: grk
**	Date: 1/12/2006
**      
**		03/05/2008 jds - Added the line to convert null list to empty string if value is null 
**		08/25/2008 grk - Increased size of input @list 
**		03/04/2015 mem - Update to use udfParseDelimitedList
**		03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList, along with the first portion of @list
**    
*****************************************************/
(
	@list varchar(max)
)
RETURNS @theTable TABLE
   (
    Item varchar(128)
   )
AS
BEGIN
	Declare @callingProcedure varchar(128) = 'MakeTableFromList: ' + IsNull(Substring(@list, 1, 25), '')
	
	INSERT INTO @theTable
		(Item)
	SELECT Value
	FROM dbo.udfParseDelimitedList(@list, ',', @callingProcedure)
	RETURN
END


GO
GRANT VIEW DEFINITION ON [dbo].[MakeTableFromList] TO [DDL_Viewer] AS [dbo]
GO
