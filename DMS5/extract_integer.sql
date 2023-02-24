/****** Object:  UserDefinedFunction [dbo].[ExtractInteger] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ExtractInteger]
/****************************************************
**
**  Desc: Returns the first contiguous integer in the text
**        Intended for use with EUS proposals that are typically numbers
**        but sometimes have letter suffixes
**
**        Returns null
**
**  Return value: error message
**
**  Parameters:
**
**  Auth:   mem
**  Date:   04/26/2016 mem - Initial release
**
*****************************************************/
(
    @text varchar(max)
)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN

    Declare @value int = TRY_CAST(@text as int)

    If @value Is Null And Not @text Is Null
    Begin
        -- @text does not contain an integer
        -- Find the first digit in @text

        Declare @startIndex int = PatIndex('%[0-9]%', @text)
        Declare @newText varchar(64)

        If @startIndex > 0
        Begin
            -- Digit found

            If @startIndex > 1 And SubString(@text, @startIndex-1,1) = '-'
            Begin
                -- Negative number
                Set @startIndex = @startIndex - 1
            End

            Set @newText = Substring(@text, @startIndex, 64)

            -- Find the first non-digit (skipping the first digit because it may be a minus sign)
            Declare @endIndex int = PatIndex('%[^0-9]%', Substring(@newText, 2, 64))

            If @endIndex > 0
            Begin
                -- Non-digit found; truncate
                Set @newText = Substring(@newText, 1, @endIndex)
            End

            Set @value = TRY_CAST(@newText as int)
        End

    End

    Return @value

END

GO
GRANT VIEW DEFINITION ON [dbo].[ExtractInteger] TO [DDL_Viewer] AS [dbo]
GO
