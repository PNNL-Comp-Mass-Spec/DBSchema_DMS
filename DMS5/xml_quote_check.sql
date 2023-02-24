/****** Object:  UserDefinedFunction [dbo].[xml_quote_check] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[xml_quote_check]
/****************************************************
**
**  Desc:   Replaces double quote characters with &quot;
**          to avoid mal-formed XML
**
**  Returns the updated text
**
**  Auth:   mem
**  Date:   02/03/2011 mem - Initial version
**          02/25/2011 mem - Now replacing < and > with &lt; and &gt;
**          05/08/2013 mem - Now changing Null strings to ''
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @text varchar(max)
)
    RETURNS varchar(max)
AS
Begin
    Set @Text = IsNull(@Text, '')
    Set @Text = Replace(@Text, '"', '&quot;')
    Set @Text = Replace(@Text, '<', '&lt;')
    Set @Text = Replace(@Text, '>', '&gt;')

    Return @Text
End

GO
GRANT VIEW DEFINITION ON [dbo].[xml_quote_check] TO [DDL_Viewer] AS [dbo]
GO
