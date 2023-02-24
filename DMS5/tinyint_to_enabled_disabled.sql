/****** Object:  UserDefinedFunction [dbo].[TinyintToEnabledDisabled] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TinyintToEnabledDisabled]
/****************************************************
**
**  Desc:
**      Returns the text 'Disabled' if @value is 0 or null, otherwise returns 'Enabled'
**
**  Auth:   mem
**  Date:   11/14/2012 mem - Initial version
**
*****************************************************/
(
    @value tinyint
)
RETURNS varchar(16)
AS
Begin
    Declare @text varchar(16)
    If IsNull(@value, 0) = 0
        Set @text = 'Disabled'
    Else
        Set @text = 'Enabled'

    Return @text
End

GO
GRANT VIEW DEFINITION ON [dbo].[TinyintToEnabledDisabled] TO [DDL_Viewer] AS [dbo]
GO
