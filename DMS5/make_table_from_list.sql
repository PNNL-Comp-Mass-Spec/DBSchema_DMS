/****** Object:  UserDefinedFunction [dbo].[make_table_from_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[make_table_from_list]
/****************************************************
**
**  Desc:
**  Returns a table filled with the contents of a delimited list
**
**  Return values:
**
**  Parameters:
**
**
**  Auth:   grk
**  Date:   01/12/2006
**          03/05/2008 jds - Added the line to convert null list to empty string if value is null
**          08/25/2008 grk - Increased size of input @list
**          03/04/2015 mem - Update to use parse_delimited_list
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list, along with the first portion of @list
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
    Declare @callingProcedure varchar(128) = 'make_table_from_list: ' + IsNull(Substring(@list, 1, 25), '')

    INSERT INTO @theTable
        (Item)
    SELECT Value
    FROM dbo.parse_delimited_list(@list, ',', @callingProcedure)
    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[make_table_from_list] TO [DDL_Viewer] AS [dbo]
GO
