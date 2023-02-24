/****** Object:  UserDefinedFunction [dbo].[number_to_string] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[number_to_string]
/****************************************************
**
**  Desc:
**      Converts the number to a string with the specified number of digits after the decimal
**
**  Auth:   mem
**  Date:   10/26/2017 mem - Initial version
**          10/27/2017 mem - Update while loop to reduce string updates
**                         - Change '-0' to '0'
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @value float,
    @digitsAfterDecimal int
)
RETURNS varchar(24)
AS
BEGIN
    Declare @valueText varchar(240)
    Declare @charsToKeep int

    -- Use the Str() function to convert to a string
    Set @valueText = Ltrim(Str(@value, 10, @digitsAfterDecimal))

    If @valueText Like '**%'
    Begin
        -- SQL server has stored '**********' in @valueText
        -- This means that after conversion, the value was more than 10 digits long
        -- Use Cast intsead
        Set @valueText = Cast(@value AS varchar(24))
    End

    If @valueText Like '%.%0' And Not @valueText Like '%e%'
    Begin
        -- The value has multiple zeroes after the decimal point, for example 34.4300
        -- (the third LIKE excludes numbers with an e, which is used for exponential notation)

        Set @charsToKeep = Len(@valueText)
        While @charsToKeep > 1 And SubString(@valueText, @charsToKeep, 1) = '0'
        Begin
            Set @charsToKeep = @charsToKeep - 1
        End

        If SubString(@valueText, @charsToKeep, 1) = '.'
        Begin
            -- Remove the trailing decimal place
            Set @charsToKeep = @charsToKeep - 1
        End

        Set @valueText = Left(@valueText, @charsToKeep)
    End

    If @valueText = '-0'
        Set @valueText = '0'

    Return @valueText
END

GO
