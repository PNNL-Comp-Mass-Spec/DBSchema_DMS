/****** Object:  UserDefinedFunction [dbo].[xml_to_html] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[xml_to_html]
/****************************************************
**
**  Desc:   Converts XML to HTML text, adding a carriage return before each XML tag
**          and changing the < and > signs to &lt; and &gt;
**
**  Returns the XML as varchar(max) text
**
**  Auth:   mem
**  Date:   06/10/2010 mem - Initial version
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @xml XML
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
GRANT VIEW DEFINITION ON [dbo].[xml_to_html] TO [DDL_Viewer] AS [dbo]
GO
