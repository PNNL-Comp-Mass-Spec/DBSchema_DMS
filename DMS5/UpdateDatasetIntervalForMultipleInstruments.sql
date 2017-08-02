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
**			04/10/2017 mem - Add parameter @instrumentsToProcess
**			04/11/2017 mem - Now passing @infoOnly to UpdateEMSLInstrumentUsageReport
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
    @DaysToProcess int = 60,
    @UpdateEMSLInstrumentUsage tinyint = 1,
    @infoOnly tinyint = 0,
    @instrumentsToProcess varchar(255) = '',
	@message varchar(512) = '' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateDatasetIntervalForMultipleInstruments', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @DaysToProcess = IsNull(@DaysToProcess, 30)
	Set @message = ''	
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @instrumentsToProcess = IsNull(@instrumentsToProcess, '')
	
	---------------------------------------------------
	-- Set up date interval and key values
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
	-- Temp table to hold list of production instruments
	---------------------------------------------------
	
	CREATE TABLE #Tmp_Instruments (
		Seq INT IDENTITY(1,1) NOT NULL,
		Instrument VARCHAR(65),
		EMSL CHAR(1),
		Tracked TINYINT
	)

	CREATE TABLE #Tmp_InstrumentFilter (
		Instrument varchar(65)
	)
	
	---------------------------------------------------
	-- Process updates for all instruments, one at a time
	-- Filter on @instrumentsToProcess if not-blank
	---------------------------------------------------
	
	BEGIN TRY 

		If Len(@instrumentsToProcess) > 0
		Begin
		
			---------------------------------------------------
			-- Get filtered list of tracked instruments
			---------------------------------------------------

			-- Populate #Tmp_InstrumentFilter using @instrumentsToProcess

			INSERT INTO #Tmp_InstrumentFilter( Instrument )
			SELECT VALUE
			FROM dbo.udfParseDelimitedList ( @instrumentsToProcess, ',', 
			       'UpdateDatasetIntervalForMultipleInstruments' )
			--
			SELECT @myError = @@Error, @myRowCount = @@RowCount

			
			INSERT INTO #Tmp_Instruments( Instrument,
			                              EMSL,
			                              Tracked )
			SELECT InstList.[Name],
			       InstList.EUS_Primary_Instrument AS EMSL,
			       InstList.Tracked
			FROM V_Instrument_Tracked InstList
			     INNER JOIN #Tmp_InstrumentFilter InstFilter
			       ON InstList.[Name] = InstFilter.Instrument
			--
			SELECT @myError = @@Error, @myRowCount = @@RowCount

		End
		Else
		Begin
		
			---------------------------------------------------
			-- Get list of tracked instruments
			---------------------------------------------------

			INSERT INTO #Tmp_Instruments( Instrument,
			                              EMSL,
			                              Tracked )
			SELECT [Name],
			       EUS_Primary_Instrument AS EMSL,
			       Tracked
			FROM V_Instrument_Tracked
			--
			SELECT @myError = @@Error, @myRowCount = @@RowCount

		End

		---------------------------------------------------
		-- Update intervals for given instrument
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
				Begin
					If @infoOnly > 0
						Print 'Call UpdateEMSLInstrumentUsageReport for Instrument ' + @instrument

					EXEC UpdateEMSLInstrumentUsageReport @instrument, @endDate, @message output, @infoonly=@infoonly
					
					If @infoOnly > 0
						Print ''
						
				End
				Else
				Begin
					If @infoOnly > 0
					Begin
						Print 'Skip call to UpdateEMSLInstrumentUsageReport for Instrument ' + @instrument
						Print ''
					End
				End
					
			END  -- </b>
		END -- </a>


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- Rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'UpdateDatasetIntervalForMultipleInstruments'
		
	END CATCH
	
	If @infoOnly <> 0 and @myError <> 0
		Print @message
		
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetIntervalForMultipleInstruments] TO [DDL_Viewer] AS [dbo]
GO
