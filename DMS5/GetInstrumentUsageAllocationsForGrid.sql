/****** Object:  StoredProcedure [dbo].[GetInstrumentUsageAllocationsForGrid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInstrumentUsageAllocationsForGrid]
/****************************************************
**
**	Desc: 
**		Get grid data for editing given usage allocations
**
**	Auth:	grk
**	Date:	01/15/2013
**	01/15/2013 grk - initial release
**	01/16/2013 grk - single fiscal year
**    
*****************************************************/
(
	@itemList TEXT, -- list of specific proposals (all if blank)
	@fiscalYear VARCHAR(256), 
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	SET @fiscalYear = ISNULL(@fiscalYear, '')
	SET @itemList = ISNULL(@itemList, '')
	
	-----------------------------------------
	-- convert item list into temp table
	-----------------------------------------
	--
	CREATE TABLE #PROPOSALS (
		Item VARCHAR(128)
	)
	--
	INSERT INTO #PROPOSALS (Item)
	SELECT Item 
	FROM dbo.MakeTableFromList(@itemList)

	
	-----------------------------------------
	-- 
	-----------------------------------------

	SELECT  Fiscal_Year ,
			Proposal_ID ,
			Title ,
			Status ,
			General ,
			FT ,
			IMS ,
			ORB ,
			EXA ,
			LTQ ,
			GC ,
			QQQ ,
			CONVERT(VARCHAR(24), Last_Updated, 101) AS Last_Updated,
			[#FY_Proposal]
	FROM    V_Instrument_Allocation_List_Report
	WHERE 
	Fiscal_Year = @fiscalYear AND
	(DATALENGTH(@itemList) = 0 OR Proposal_ID IN (SELECT Item FROM #PROPOSALS))

	RETURN @myError	



GO
GRANT EXECUTE ON [dbo].[GetInstrumentUsageAllocationsForGrid] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetInstrumentUsageAllocationsForGrid] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentUsageAllocationsForGrid] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentUsageAllocationsForGrid] TO [PNL\D3M580] AS [dbo]
GO
