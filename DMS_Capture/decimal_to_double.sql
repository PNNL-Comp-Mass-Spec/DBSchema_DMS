/****** Object:  UserDefinedFunction [dbo].[udfDecimalToDouble] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udfDecimalToDouble]
/****************************************************
**  Test udf
**
**  Auth:   mem
**  Date:   02/20/2020
**
****************************************************/
(
    @value Decimal(9,5)
)
RETURNS float
AS
BEGIN
    Declare @newValue Float

    Set @newValue = @value

    RETURN  @value
END



GO
