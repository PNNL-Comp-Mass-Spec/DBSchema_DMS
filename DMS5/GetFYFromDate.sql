/****** Object:  UserDefinedFunction [dbo].[GetFYFromDate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetFYFromDate
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
**	Date:	03/15/2012
**    
*****************************************************/
(
	@RawDate Datetime
)
RETURNS INT
AS
	BEGIN
	IF @RawDate IS NULL SET @RawDate = GETDATE()
	DECLARE @yr Datetime = CASE WHEN DATEPART(mm, @RawDate) > 9 THEN DATEADD(YY, 1, @RawDate) ELSE @RawDate END 
	RETURN DATEPART(YEAR, @yr)
	END


GO
