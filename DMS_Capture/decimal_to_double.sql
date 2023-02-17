/****** Object:  UserDefinedFunction [dbo].[decimal_to_double] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[decimal_to_double]
/****************************************************
**  Test udf
**
**  Auth:   mem
**  Date:   02/20/2020
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
