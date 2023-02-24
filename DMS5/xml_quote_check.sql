/****** Object:  UserDefinedFunction [dbo].[XMLQuoteCheck] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[XMLQuoteCheck]
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
**
*****************************************************/
(
    @Text varchar(max)
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
GRANT VIEW DEFINITION ON [dbo].[XMLQuoteCheck] TO [DDL_Viewer] AS [dbo]
GO
