/****** Object:  UserDefinedFunction [dbo].[CheckPlural] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CheckPlural]
/****************************************************
**
**  Desc: Returns @TextIfOneItem if @Count is 1; otherwise, returns @TextIfZeroOrMultiple
**
**  Return value: error message
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/05/2013 mem - Initial release
**
*****************************************************/
(
    @Count int,
    @TextIfOneItem varchar(128) = 'item',
    @TextIfZeroOrMultiple varchar(128) = 'items'
)
RETURNS varchar(128)
AS
BEGIN
    Declare @Value varchar(128)

    If IsNull(@Count, 0) = 1
        Set @Value = @TextIfOneItem
    Else
        Set @Value = @TextIfZeroOrMultiple

    Return @Value

END

GO
