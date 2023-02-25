/****** Object:  UserDefinedFunction [dbo].[get_fiscal_year_from_date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_fiscal_year_from_date]
/****************************************************
**
**  Desc:
**      Returns Fiscal year for given date
**
**  Return value: Fiscal year, e.g. 2021
**
**  Auth:   grk
**  Date:   03/15/2012
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @rawDate Datetime
)
RETURNS INT
AS
BEGIN
    IF @RawDate IS NULL SET @RawDate = GETDATE()
    DECLARE @yr Datetime = CASE WHEN DATEPART(month, @RawDate) > 9 THEN DATEADD(year, 1, @RawDate) ELSE @RawDate END
    RETURN DATEPART(YEAR, @yr)
END


GO
GRANT VIEW DEFINITION ON [dbo].[get_fiscal_year_from_date] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_fiscal_year_from_date] TO [public] AS [dbo]
GO
