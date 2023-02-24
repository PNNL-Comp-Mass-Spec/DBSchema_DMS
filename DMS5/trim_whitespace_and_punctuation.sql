/****** Object:  UserDefinedFunction [dbo].[TrimWhitespaceAndPunctuation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TrimWhitespaceAndPunctuation]
/****************************************************
**
**  Desc:   Removes whitespace (including Cr, Lf, and tab) plus punctuation from the start and end of text
**          Punctuation characters: period, comma, semicolon, single quote, or double quote
**
**  Return value: Trimmed text
**
**  Auth:   mem
**  Date:   09/11/2020 mem - Initial release (modelled after UDF ScrubWhitespace)
**
*****************************************************/
(
    @text varchar(max)
)
RETURNS varchar(max)
AS
BEGIN

    Declare @newText varchar(max)

    Set @newText = LTrim(RTrim(IsNull(@text, '')))

    Declare @continueChecking tinyint
    Declare @matchChar varchar(1)

    Set @continueChecking = 1
    While @continueChecking = 1 and Len(@newText) > 0
    Begin
        -- Check for Cr, Lf, Tab, or punctuation on the left edge of the text
        Set @matchChar = Substring(@newText, 1, 1)

        If    @matchChar = Char(10) -- CR
           OR @matchChar = Char(13) -- LF
           OR @matchChar = Char(9)  -- Tab
           OR @matchChar IN ('.', ',', ';', '''', '"')
        Begin
            Set @newText = LTrim(Substring(@newText, 2, Len(@newText)-1))
        End
        Else
        Begin
            Set @continueChecking = 0
        End
    End

    Set @continueChecking = 1
    While @continueChecking = 1 and Len(@newText) > 0
    Begin
        -- Check for Cr, Lf, Tab, or punctuation on the right edge of the text
        Set @matchChar = Substring(@newText, Len(@newText), 1)

        If    @matchChar = Char(10) -- CR
           OR @matchChar = Char(13) -- LF
           OR @matchChar = Char(9)  -- Tab
           OR @matchChar IN ('.', ',', ';', '''', '"')
        Begin
            Set @newText = RTrim(Substring(@newText, 1, Len(@newText)-1))
        End
        Else
        Begin
            Set @continueChecking = 0
        End
    End

    Return @newText

END

GO
