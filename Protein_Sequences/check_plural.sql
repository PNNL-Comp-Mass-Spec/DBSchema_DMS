/****** Object:  UserDefinedFunction [dbo].[check_plural] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[check_plural]
/****************************************************
**
**  Desc: Returns @TextIfOneItem if @Count is 1; otherwise, returns @TextIfZeroOrMultiple
**
**  Return value: error message
**
**  Auth:   mem
**  Date:   03/05/2013 mem - Initial release
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @count int,
    @textIfOneItem varchar(128) = 'item',
    @textIfZeroOrMultiple varchar(128) = 'items'
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
