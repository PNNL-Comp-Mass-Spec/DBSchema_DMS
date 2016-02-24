/****** Object:  StoredProcedure [dbo].[UpdateDatasetIntervalForMultipleInstruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateDatasetIntervalForMultipleInstruments
/****************************************************
**
**  Desc: 
**    Updates dataset interval and creates entries 
**    for long intervals in the intervals table for 
**    all production instruments 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	02/09/2012 
**			03/07/2012 mem - Added parameters @DaysToProcess, @infoOnly, and @message
**			03/21/2012 grk - Added call to UpdateEMSLInstrumentUsageReport
**			03/22/2012 mem - Added parameter @UpdateEMSLInstrumentUsage
**			03/26/2012 grk - Added call to UpdateEMSLInstrumentUsageReport for previous month
**			03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**			03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - modified algorithm
**			08/02/2012 mem - Updated @DaysToProcess to default to 60 days instead of 30 days
**          09/18/2012 grk - only do EMSL instrumet updates for EMLS instruments 
**          10/06/2012 grk - removed update of EMSL usage report for previous month
**			03/12/2014 grk - Added processing for "tracked" instruments (OMCDA-1058)
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
    @DaysToProcess int = 60,
    @UpdateEMSLInstrumentUsage tinyint = 1,
    @infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @DaysToProcess = IsNull(@DaysToProcess, 30)
	Set @message = ''	
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- set up date interval and key values
	---------------------------------------------------
	
	DECLARE @endDate DATETIME =  GETDATE()
	DECLARE @startDate DATETIME = DATEADD(DAY, -@DaysToProcess, @endDate)
	DECLARE @currentYear INT = DATEPART(YEAR, @endDate)
	DECLARE @currentMonth INT = DATEPART(MONTH, @endDate)
	DECLARE @day INT = DATEPART(DAY, @endDate)
	DECLARE @hour INT = DATEPART(HOUR, @endDate)
	DECLARE @prevDate DATETIME = DATEADD(MONTH, -1, @endDate)						
	DECLARE @prevMonth INT = DATEPART(MONTH, @prevDate)
	DECLARE @prevYear INT = DATEPART(YEAR, @prevDate)

	DECLARE @nextMonth INT = DATEPART(MONTH, DATEADD(MONTH, 1, @endDate))
	DECLARE @nextYear INT = DATEPART(YEAR, DATEADD(MONTH, 1, @endDate))
	DECLARE @bonm DATETIME = CONVERT(VARCHAR(12), @nextMonth) + '/1/' + CONVERT(VARCHAR(12), @nextYear)
	
	---------------------------------------------------
	-- temp table to hold list of production instruments
	---------------------------------------------------
	
	CREATE TABLE #Tmp_Instruments (
		Seq INT IDENTITY(1,1) NOT NULL,
		Instrument VARCHAR(65),
		EMSL CHAR(1),
		Tracked TINYINT
	)

	---------------------------------------------------
	-- process updates for all instruments, one at a time
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		-- get list of tracked instruments
		---------------------------------------------------

		INSERT INTO #Tmp_Instruments (Instrument, EMSL, Tracked)
		SELECT [Name], EUS_Primary_Instrument AS EMSL, Tracked FROM V_Instrument_Tracked

		---------------------------------------------------
		-- update intervals for given instrument
		---------------------------------------------------
		
		DECLARE @instrument VARCHAR(64)
		DECLARE @emslInstrument CHAR(1)
		DECLARE @tracked TINYINT
		DECLARE @index INT = 0
		DECLARE @done TINYINT = 0

		WHILE @done = 0
		BEGIN -- <a>
			SET @instrument = NULL 
			SELECT TOP 1 @instrument = Instrument, @emslInstrument = EMSL, @tracked = Tracked
			FROM #Tmp_Instruments 
			WHERE Seq > @index
			
			SET @index = @index + 1
			
			IF @instrument IS NULL 
			BEGIN 
				SET @done = 1
			END 
			ELSE 
			BEGIN -- <b>
				EXEC UpdateDatasetInterval @instrument, @startDate, @bonm, @message output, @infoOnly=@infoOnly
				
				If @UpdateEMSLInstrumentUsage <> 0 AND (@emslInstrument = 'Y' OR @tracked = 1)
				BEGIN --<c>					
					EXEC UpdateEMSLInstrumentUsageReport @instrument, @endDate, @message output
				END --<c>
					
			END  -- </b>
		END -- </a>


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	If @infoOnly <> 0 and @myError <> 0
		Print @message
		
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetIntervalForMultipleInstruments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetIntervalForMultipleInstruments] TO [PNL\D3M580] AS [dbo]
GO
