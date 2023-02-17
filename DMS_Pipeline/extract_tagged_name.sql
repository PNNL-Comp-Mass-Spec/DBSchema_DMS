/****** Object:  UserDefinedFunction [dbo].[ExtractTaggedName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.ExtractTaggedName
/****************************************************
**
**  Desc:
**  Examines the text provided and looks for substring
**  that is preceded by given tag, and terminated by
**  space character or end of text
**
**  Return values: substring, or '' if none found
**
**  Parameters: @tag - The tag to look for
**              @text - The text to search
**
**  Auth:   grk
**  Date:   04/13/2009 grk - Initial release (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          07/29/2009 mem - Updated to return nothing if @tag is not found in @text
**                         - Added additional delimiters when searching for the end of the text to return after the tag
**          08/23/2012 mem - Expanded @tag from varchar(12) to varchar(64)
**
*****************************************************/
(
    @tag varchar(64) = 'DTA:',
    @text varchar(4096)
)
RETURNS VARCHAR(256)
AS
BEGIN
    declare @idxStart int
    declare @idxEnd int

    Declare @ExtractedText varchar(256)
    Set @ExtractedText = ''

    set @idxStart = CHARINDEX(@tag, @text)

    If @idxStart >0
    Begin
        -- Match found
        -- Extract the text from the end of the tag to the next space, semicolon, colon, or comma
        --- (or to the end of the line, if none of those delimeters is found)

        Set @idxStart = @idxStart + Len(@tag)
        Set @ExtractedText = RTRIM(LTRIM(SUBSTRING (@text, @idxStart, LEN(@text) )))

        set @idxEnd = PATINDEX ('%[ ;,:\/]%', @ExtractedText)
        if @idxEnd > 0
            set @ExtractedText = RTRIM(SUBSTRING (@ExtractedText, 1, @idxEnd-1 ))

    End

    RETURN @ExtractedText
END


GO
GRANT VIEW DEFINITION ON [dbo].[ExtractTaggedName] TO [DDL_Viewer] AS [dbo]
GO
