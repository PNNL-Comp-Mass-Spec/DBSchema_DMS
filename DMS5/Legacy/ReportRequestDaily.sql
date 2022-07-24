/****** Object:  StoredProcedure [dbo].[ReportRequestDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE ReportRequestDaily
/****************************************************
**
**	Desc: Generates report of daily request counts
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 3/5/2005
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
		r int  NULL,
		h int  NULL,
		t int  NULL,
		ds int Null
	) 
	-- date of first entry in table
	--
	declare @d datetime
	set @d = '2/19/2003'

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
			(d, r, h, t, ds)
		VALUES     
			(@d, 0, 0, 0, 0)
	end

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set 
	t.r = q.Request, t.h= q.History, t.t=q.Total, t.ds=q.Datasets
	from #T as t join
	(
		SELECT  top 100 percent date, Request, History, Total, Datasets
		FROM         V_Request_count_by_day
		order by date
	) as q on 
	(
	(DATEPART(yy, t.d) = DATEPART(yy, q.date) ) AND 
	(DATEPART(mm, t.d) = DATEPART(mm, q.date) ) AND 
	(DATEPART(dd, t.d) = DATEPART(dd, q.date) ) 
	)


	-- dump contents of table
	--
	select d as Date, t as [Total entered], r as [Remaining in request/schedule queue], h as [In history list], ds as [Datasets Created] from #T order by d


	RETURN 



GO
GRANT VIEW DEFINITION ON [dbo].[ReportRequestDaily] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportRequestDaily] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportRequestDaily] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportRequestDaily] TO [Limited_Table_Write] AS [dbo]
GO
