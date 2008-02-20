/****** Object:  StoredProcedure [dbo].[ReportDatasetDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReportDatasetDaily
/****************************************************
**
**	Desc: Generates report of daily dataset counts
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 8/22/2002
**    
*****************************************************/
--	@message varchar(256) = '' output
AS
	SET NOCOUNT ON

	-- make a temporary table 
	-- to hold sequential dates of daily totals
	--
	CREATE TABLE #T (
		d datetime  NULL,
		num int  NULL
	) 
	-- date of first entry in table
	--
	declare @d datetime
	set @d = '4/1/2001'

	-- how many entries in table
	--
	declare @x int
	set @x = datediff(dd, @d, getdate())

	 
	-- generate given number of sequential days in table
	-- starting from given date
	--
	while (@x > 0)
	begin
		set @d = dateadd(dd, 1, @d)
		set @x = @x -1
		INSERT INTO #T
			(d, num)
		VALUES     
			(@d, 0)
	end

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.num = q.[Number of Analysis Jobs Completed]
	from #T as t join
	(
		SELECT  top 100 percent date, [Number of Analysis Jobs Completed]
		FROM         V_Analysis_Job_completed_count_by_day
		order by date
	) as q on 
	(
	(DATEPART(yy, t.d) = DATEPART(yy, q.date) ) AND 
	(DATEPART(mm, t.d) = DATEPART(mm, q.date) ) AND 
	(DATEPART(dd, t.d) = DATEPART(dd, q.date) ) 
	)


	-- dump contents of table
	--
	select d as Date, num as [Number of Analysis Jobs] from #T order by d


	RETURN 


GO
GRANT EXECUTE ON [dbo].[ReportDatasetDaily] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[ReportDatasetDaily] TO [DMS2_SP_User]
GO
