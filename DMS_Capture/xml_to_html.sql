/****** Object:  UserDefinedFunction [dbo].[XmlToHTML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[XmlToHTML]
/****************************************************
**
**  Desc:   Converts XML to HTML text, adding a carriage return before each XML tag
**          and changing the < and > signs to &lt; and &gt;
**
**  Returns the XML as varchar(max) text
**
**  Auth:   mem
**  Date:   06/10/2010 mem - Initial version
**
*****************************************************/
(
    @XML XML
)
    RETURNS varchar(max)
AS
Begin

    Declare @CharLoc int
    Declare @Text varchar(MAX)
    Declare @CRLF varchar(2)

    If @XML Is Null
        Set @Text = ''
    Else
    Begin
        Set @CRLF = CHAR(13) + CHAR(10)

        Set @Text = LTRIM(RTRIM(REPLACE(CONVERT(varchar(MAX), @XML), '<', @CRLF + '<')))
        Set @Text = '<pre>' + REPLACE(REPLACE(@Text, '<', '&lt;'), '>', '&gt;') + '</pre>'

    End

    Return @Text
End

GO
GRANT VIEW DEFINITION ON [dbo].[XmlToHTML] TO [DDL_Viewer] AS [dbo]
GO
