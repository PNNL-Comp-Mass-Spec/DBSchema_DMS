/****** Object:  UserDefinedFunction [dbo].[GetFiscalYearStart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetFiscalYearStart
/****************************************************
**
**	Desc: 
**  Returns starting date for fiscal year N years ago
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
	@numberOfRecentYears int
)
RETURNS Datetime
AS
	BEGIN
	DECLARE @yr INT = DATEPART(YY, DATEADD(YY, -1 * @numberOfRecentYears, GETDATE()))
	DECLARE @fy_start varchar(24) = '10/1/' + CONVERT(varchar(12), @yr);
	DECLARE @dt DATETIME = CONVERT(DATETIME, @fy_start)
	RETURN @dt
	END

GO
GRANT EXECUTE ON [dbo].[GetFiscalYearStart] TO [public] AS [dbo]
GO
