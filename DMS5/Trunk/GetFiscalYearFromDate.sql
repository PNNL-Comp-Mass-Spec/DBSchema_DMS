/****** Object:  UserDefinedFunction [dbo].[GetFiscalYearFromDate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetFiscalYearFromDate
/****************************************************
**
**	Desc: 
**  Returns Fiscal year for given date
**
**	Return value: person
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	07/18/2011
**    
*****************************************************/
(
	@RawDate Datetime 
)
RETURNS VARCHAR(32)
AS
	BEGIN
	DECLARE @yr Datetime = CASE WHEN DATEPART(mm, @RawDate) > 9 THEN DATEADD(YY, 1, @RawDate) ELSE @RawDate END 
	RETURN 'FY_' + RIGHT(CONVERT(VARCHAR(24), @yr, 101), 2)
	END

GO
