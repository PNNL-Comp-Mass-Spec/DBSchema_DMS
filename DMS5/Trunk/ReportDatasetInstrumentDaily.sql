/****** Object:  StoredProcedure [dbo].[ReportDatasetInstrumentDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReportDatasetInstrumentDaily
/****************************************************
**
**	Desc: Generates report of daily dataset counts
**			broken down by instrument
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 8/22/2002
**		Date: 11/24/2003 dac Added QTOF
**		Date: 03/15/2004 grk Fixed for FTICR_9T variants
**		Date: 10/27/2004 grk Added LTQ, LTQ_FT
**		Date: 12/2/2004 grk Fixed "loose naming" problem
**		Date: 02/20/2006 grk Added Orbitrap
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
		LCQ int  NULL,
		FTICR_9T int  NULL,
		FTICR_11T int  NULL,
		QTOF int NULL,
		LTQ int NULL,
		LTQ_FT int NULL,
		FTICR_3T int  NULL,
		FTICR_7T int  NULL,
		Agilent int  NULL,
		LTQ_Orb_1 int NULL
	) 
	-- date of first entry in table
	--
	declare @d datetime
	set @d = '4/20/2001'

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
		set @x = @x - 1
		INSERT INTO #T
			(d, LCQ, FTICR_9T, FTICR_11T, FTICR_3T, FTICR_7T, QTOF, LTQ, LTQ_FT, Agilent, LTQ_Orb_1)
		VALUES     
			(@d, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	end

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.LCQ = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE 'LCQ%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.FTICR_11T = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE '11T_FTICR%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.FTICR_7T = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument = '7T_FTICR')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.FTICR_9T = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE '9T_FTICR%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)
	 
	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.FTICR_3T = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument = '3T_FTICR')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)
	
	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.QTOF = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE 'QTOF_MM')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)
	
	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.LTQ = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE 'LTQ%') AND NOT (Instrument LIKE 'LTQ_FT%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.LTQ_FT = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE '%LTQ_FT%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.Agilent = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument LIKE 'Agilent%')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)

	-- update the daily totals in the table
	-- from the dataset counts in DMS
	--
	update t
	set t.LTQ_Orb_1 = q.[Total]
	from #T as t join
	(
		SELECT     TOP 100 PERCENT DATEPART(dd, Created) AS day, DATEPART(mm, Created) AS month, DATEPART(yy, Created) AS year, COUNT(*) AS Total
		FROM         V_Dataset_Detail_Report
		WHERE     (Instrument = 'LTQ_Orb_1')
		GROUP BY DATEPART(dd, Created), DATEPART(mm, Created), DATEPART(yy, Created)
	) as q on 
	(
	(DATEPART(yy, t.d) = q.year ) AND 
	(DATEPART(mm, t.d) = q.month ) AND 
	(DATEPART(dd, t.d) = q.day ) 
	)
	

	-- dump contents of table
	--
	select d as Date, LCQ, LTQ, FTICR_11T, FTICR_9T, LTQ_FT, QTOF, FTICR_7T, FTICR_3T, Agilent, LTQ_Orb_1 from #T order by d


	RETURN

GO
GRANT EXECUTE ON [dbo].[ReportDatasetInstrumentDaily] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportDatasetInstrumentDaily] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportDatasetInstrumentDaily] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportDatasetInstrumentDaily] TO [PNL\D3M580] AS [dbo]
GO
