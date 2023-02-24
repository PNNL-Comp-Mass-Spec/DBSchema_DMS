/****** Object:  UserDefinedFunction [dbo].[get_fiscal_year_start] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_fiscal_year_start]
/****************************************************
**
**  Desc:   Returns starting date for fiscal year N years ago
**
**  Return value: Fiscal year start date
**
**  Auth:   grk
**  Date:   07/18/2011 grk - Initial Version
**          02/10/2022 mem - Update to work properly when running between January 1 and September 30
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @numberOfRecentYears int
)
RETURNS Datetime
AS
BEGIN
    Declare @referenceDate Datetime = GetDate()

    Declare @targetYear Int = DATEPART(YY, DATEADD(YY, -1 * @numberOfRecentYears, @referenceDate))
    If Month(@referenceDate) < 10
        Set @targetYear = @targetYear - 1

    Declare @startDateText varchar(24) = '10/1/' + Cast(@targetYear As varchar(12))
    Declare @fiscalYearStart Datetime = Cast(@startDateText As Datetime)

    Return @fiscalYearStart
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_fiscal_year_start] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_fiscal_year_start] TO [public] AS [dbo]
GO
