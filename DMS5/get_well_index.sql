/****** Object:  UserDefinedFunction [dbo].[get_well_index] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_well_index]
/****************************************************
**
**  Desc:
**      Given 96 well plate well number, return the index position of the well
**
**  Return values: next well number, or null if none found
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/15/2000
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/09/2024 mem - Return 0 if @wellNumber is an empty string or only a single character
**                         - Capitalize the first character of @wellNumber
**
*****************************************************/
(
    @wellNumber varchar(8)
)
RETURNS int
AS
BEGIN
    Set @wellNumber = LTrim(RTrim(Coalesce(@wellNumber, '')));

    If Len(@wellNumber) < 2
    Begin
        RETURN 0;
    End

    Declare @index int = 0

    Declare @wpRow smallint
    Declare @wpRowCharBase smallint = ASCII('A')

    Declare @wpCol smallint
    Declare @numCols smallint = 12

    -- Get row and col for current well

    Set @wpRow = ASCII(Upper(Substring(@wellNumber, 1, 1))) - @wpRowCharBase
    Set @wpCol = Convert(smallint, Substring(@wellNumber, 2, 20))

    If @wpRow <= 8 And @wpRow >= 0 And @wpCol <= 12 And @wpCol >= 0
    Begin
        Set @index = (@wpRow * @numCols) + @wpCol
    End

    RETURN @index
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_well_index] TO [DDL_Viewer] AS [dbo]
GO
