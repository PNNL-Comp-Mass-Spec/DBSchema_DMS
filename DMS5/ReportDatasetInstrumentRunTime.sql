/****** Object:  StoredProcedure [dbo].[ReportDatasetInstrumentRunTime] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReportDatasetInstrumentRunTime
/****************************************************
**
**	Desc: 
**	Generates dataset runtime and interval 
**	statistics for specified instrument
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	05/26/2011 grk - initial release
**			01/31/2012 grk - Added Interval column to output and made separate interval rows an option
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@startDate varchar(24) = '',
	@endDate varchar(24) = '',
	@instrumentName VARCHAR(64) = 'Exact01',
	@reportOptions VARCHAR(64) = 'Show All', -- 'No Intervals', 'Intervals Only'
	@message varchar(256) output
)
AS
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	
	declare @weeksInRange int
	declare @stDate datetime
	declare @eDate datetime

	declare @msg varchar(256)

	declare @eDateAlternate datetime

	BEGIN TRY 

	Set @message = ''
	
	--------------------------------------------------------------------
	-- If @endDate is empty, auto-set to the end of the current day
	--------------------------------------------------------------------
	--
	If IsNull(@endDate, '') = '' OR @endDate = ''
	Begin
		Set @eDateAlternate = CONVERT(datetime, convert(varchar(32), GETDATE(), 101))
		Set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
		Set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
		Set @endDate = Convert(varchar(32), @eDateAlternate, 121)
	End
	Else
	Begin
		If IsDate(@endDate) = 0
		Begin
			set @msg = 'End date "' + @endDate + '" is not a valid date'
			RAISERROR (@msg, 11, 15)
		End
	End
		
	--------------------------------------------------------------------
	-- Check whether @endDate only contains year, month, and day
	--------------------------------------------------------------------
	--
	set @eDate = CONVERT(DATETIME, @endDate, 102) 

	set @eDateAlternate = Convert(datetime, Floor(Convert(float, @eDate)))
	
	If @eDate = @eDateAlternate
	Begin
		-- @endDate only specified year, month, and day
		-- Update @eDateAlternate to span thru 23:59:59.997 on the given day,
		--  then copy that value to @eDate
		
		set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
		set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
		set @eDate = @eDateAlternate
	End
	
	--------------------------------------------------------------------
	-- If @startDate is empty, auto-set to 2 weeks before @eDate
	--------------------------------------------------------------------
	--
	If IsNull(@startDate, '') = ''
		Set @stDate = DateAdd(day, -14, Convert(datetime, Floor(Convert(float, @eDate))))
	Else
	Begin
		If IsDate(@startDate) = 0
		Begin
			set @msg = 'Start date "' + @startDate + '" is not a valid date'
			RAISERROR (@msg, 11, 16)
		End

		Set @stDate = CONVERT(DATETIME, @startDate, 102) 
	End

	---------------------------------------------------
	-- Generate report
	---------------------------------------------------

	SELECT * 
	FROM dbo.GetDatasetInstrumentRuntime(@stDate, @eDate, @instrumentName, @reportOptions)
	ORDER BY Seq

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[ReportDatasetInstrumentRunTime] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportDatasetInstrumentRunTime] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportDatasetInstrumentRunTime] TO [PNL\D3M578] AS [dbo]
GO
