/****** Object:  UserDefinedFunction [dbo].[make_table_from_list_delim] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[make_table_from_list_delim]
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
**  Date:   01/08/2007
**          03/05/2008 jds - added the line to convert null list to empty string if value is null
**          09/16/2009 mem - Expanded @list to varchar(max)
**          04/07/2016 mem - Update to use parse_delimited_list
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list, along with the first portion of @list
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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

    Declare @callingProcedure varchar(128) = 'make_table_from_list_delim: ' + IsNull(Substring(@list, 1, 25), '')

    INSERT INTO @theTable
        (Item)
    SELECT Value
    FROM dbo.parse_delimited_list(@list, @delimiter, @callingProcedure)
    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[make_table_from_list_delim] TO [DDL_Viewer] AS [dbo]
GO
