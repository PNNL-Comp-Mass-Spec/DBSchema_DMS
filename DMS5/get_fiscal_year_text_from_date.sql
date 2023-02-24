/****** Object:  UserDefinedFunction [dbo].[get_fiscal_year_text_from_date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_fiscal_year_text_from_date]
/****************************************************
**
**  Desc:
**  Returns Fiscal year for given date
**
**  Return value: person
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/18/2011
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @rawDate Datetime
)
RETURNS VARCHAR(32)
AS
    BEGIN
    DECLARE @yr Datetime = CASE WHEN DATEPART(mm, @RawDate) > 9 THEN DATEADD(YY, 1, @RawDate) ELSE @RawDate END
    RETURN 'FY_' + RIGHT(CONVERT(VARCHAR(24), @yr, 101), 2)
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_fiscal_year_text_from_date] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_fiscal_year_text_from_date] TO [public] AS [dbo]
GO
