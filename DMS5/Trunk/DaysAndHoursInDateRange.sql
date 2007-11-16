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
**		Auth: mem
**		Date: 11/07/2007
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
		set @d = dateadd(hh, @HourInterval, @d)

		INSERT INTO @dates
			(dy)
		VALUES     
			(@d)
	end   
	
	RETURN
END


GO
GRANT SELECT ON [dbo].[DaysAndHoursInDateRange] TO [public]
GO
