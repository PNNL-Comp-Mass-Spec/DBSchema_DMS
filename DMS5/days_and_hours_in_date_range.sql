/****** Object:  UserDefinedFunction [dbo].[DaysAndHoursInDateRange] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.DaysAndHoursInDateRange 
/****************************************************
**
**	Desc: Returns a series of date/time values spaced @HourInterval hours apart
**
**	Auth:	mem
**	Date:	11/07/2007
**			11/29/2007 mem - Fixed bug that started at @startDate + @HourInterval instead of at @startDate
**    
*****************************************************/
( 
	@startDate datetime = '1/1/2005', 
	@endDate datetime = '1/21/2005',
	@HourInterval tinyint = 6
)
RETURNS @dates TABLE
   (
    dy   datetime
   )
AS
BEGIN
	-- date of first entry in table
	--
	declare @d datetime
	set @d = @startDate
	 
	-- generate given number of sequential date/time values and place in table
	-- starting from given date
	--
	while (@d < @endDate)
	begin
		INSERT INTO @dates
			(dy)
		VALUES     
			(@d)

		set @d = dateadd(hh, @HourInterval, @d)
	end   
	
	RETURN
END


GO
GRANT VIEW DEFINITION ON [dbo].[DaysAndHoursInDateRange] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[DaysAndHoursInDateRange] TO [public] AS [dbo]
GO
