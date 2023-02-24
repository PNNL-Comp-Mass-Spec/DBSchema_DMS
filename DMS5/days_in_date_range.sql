/****** Object:  UserDefinedFunction [dbo].[DaysInDateRange] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.DaysInDateRange 
( 
	@startDate datetime = '1/1/2005', 
	@endDate datetime = '1/21/2005'
)
RETURNS @dates TABLE
   (
    dy   datetime
   )
AS
BEGIN
	-- how many entries in table
	--
	declare @x int
--	set @x = datediff(dd, @startDate, @endDate)
	set @x = 0

	-- date of first entry in table
	--
	declare @d datetime
	set @d = @startDate
	 
	-- generate given number of sequential days in table
	-- starting from given date
	--
	while (@d < @endDate)
	begin
		set @d = dateadd(dd, @x, @startDate)
		set @x = @x + 1
		INSERT INTO @dates
			(dy)
		VALUES     
			(@d)
	end   RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[DaysInDateRange] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[DaysInDateRange] TO [public] AS [dbo]
GO
