/****** Object:  StoredProcedure [dbo].[UpdateDatasetIntervalForMultipleInstruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDatasetIntervalForMultipleInstruments]
/****************************************************
**
**  Desc:
**      Updates dataset interval and creates entries
**      for long intervals in the intervals table for
**      all production instruments
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/09/2012 grk - Initial version
**          03/07/2012 mem - Added parameters @daysToProcess, @infoOnly, and @message
**          03/21/2012 grk - Added call to UpdateEMSLInstrumentUsageReport
**          03/22/2012 mem - Added parameter @updateEMSLInstrumentUsage
**          03/26/2012 grk - Added call to UpdateEMSLInstrumentUsageReport for previous month
**          03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**          03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - modified algorithm
**          08/02/2012 mem - Updated @daysToProcess to default to 60 days instead of 30 days
**          09/18/2012 grk - Only do EMSL instrument updates for EMSL instruments
**          10/06/2012 grk - Removed update of EMSL usage report for previous month
**          03/12/2014 grk - Added processing for "tracked" instruments (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/10/2017 mem - Add parameter @instrumentsToProcess
**          04/11/2017 mem - Now passing @infoOnly to UpdateEMSLInstrumentUsageReport
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass @eusInstrumentId to UpdateEMSLInstrumentUsageReport for select instruments
**          01/28/2022 mem - Call UpdateEMSLInstrumentUsageReport for both the current month, plus also previous months if @daysToProcess is greater than 15
**
*****************************************************/
(
    @daysToProcess int = 60,                  -- Also affects whether UpdateEMSLInstrumentUsageReport is called for previous months
    @updateEMSLInstrumentUsage tinyint = 1,
    @infoOnly tinyint = 0,
    @instrumentsToProcess varchar(255) = '',
    @message varchar(512) = '' output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetIntervalForMultipleInstruments', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @daysToProcess = IsNull(@daysToProcess, 60)
    If @daysToProcess < 10
        Set @daysToProcess = 10

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @instrumentsToProcess = IsNull(@instrumentsToProcess, '')

    ---------------------------------------------------
    -- Set up date interval and key values
    ---------------------------------------------------

    Declare @endDate DATETIME = GETDATE()
    Declare @instrumentUsageMonth DATETIME = GETDATE()

    -- Update instrument usage for the current month, plus possibly the last few months, depending on @daysToProcess
    -- For example, if @daysToProcess is 60, will call UpdateEMSLInstrumentUsageReport for this month plus the last two months
    Declare @instrumentUsageMonthsToUpdate float = 1 + Round(@daysToProcess / 31.0, 0)

    Declare @startDate DATETIME = DATEADD(DAY, -@daysToProcess, @endDate)
    Declare @currentYear INT = DATEPART(YEAR, @endDate)
    Declare @currentMonth INT = DATEPART(MONTH, @endDate)
    Declare @day INT = DATEPART(DAY, @endDate)
    Declare @hour INT = DATEPART(HOUR, @endDate)
    Declare @prevDate DATETIME = DATEADD(MONTH, -1, @endDate)
    Declare @prevMonth INT = DATEPART(MONTH, @prevDate)
    Declare @prevYear INT = DATEPART(YEAR, @prevDate)

    Declare @nextMonth INT = DATEPART(MONTH, DATEADD(MONTH, 1, @endDate))
    Declare @nextYear INT = DATEPART(YEAR, DATEADD(MONTH, 1, @endDate))
    Declare @bonm DATETIME = CONVERT(varchar(12), @nextMonth) + '/1/' + CONVERT(varchar(12), @nextYear)

    ---------------------------------------------------
    -- Temp table to hold list of production instruments
    ---------------------------------------------------

    CREATE TABLE #Tmp_Instruments (
        Seq INT IDENTITY(1,1) NOT NULL,
        Instrument varchar(65),
        EMSL CHAR(1),
        Tracked tinyint,
        EUS_Instrument_ID Int Null,
        Use_EUS_ID tinyint Not Null
    )

    CREATE TABLE #Tmp_InstrumentFilter (
        Instrument varchar(65)
    )

    Create Table #Tmp_EUS_IDs_Processed (
        EUS_Instrument_ID Int Not Null,
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
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT InstList.[Name],
                   InstList.EUS_Primary_Instrument AS EMSL,
                   InstList.Tracked,
                   InstList.EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked InstList
                 INNER JOIN #Tmp_InstrumentFilter InstFilter
                   ON InstList.[Name] = InstFilter.Instrument
            Order By IsNull(InstList.EUS_Instrument_ID, 0), InstList.[Name]
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
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT [Name],
                   EUS_Primary_Instrument AS EMSL,
                   Tracked,
                   EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked
            Order By IsNull(EUS_Instrument_ID, 0), [Name]
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount

        End

        ---------------------------------------------------
        -- Flag instruments where we need to use EUS instrument ID
        -- instead of instrument name when calling UpdateEMSLInstrumentUsageReport
        ---------------------------------------------------

        UPDATE #Tmp_Instruments
        SET Use_EUS_ID = 1
        FROM #Tmp_Instruments
                INNER JOIN ( SELECT InstName.IN_name,
                                    InstMapping.EUS_Instrument_ID
                            FROM T_Instrument_Name InstName
                                INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                                    ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                                INNER JOIN ( SELECT EUS_Instrument_ID
                                             FROM T_Instrument_Name InstName
                                                    INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                                                    ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                                             WHERE Not EUS_Instrument_ID Is Null
                                             GROUP BY EUS_Instrument_ID
                                             HAVING Count(*) > 1 
                                           ) LookupQ
                                    ON InstMapping.EUS_Instrument_ID = LookupQ.EUS_Instrument_ID 
                           ) FilterQ
                ON #Tmp_Instruments.EUS_Instrument_ID = FilterQ.EUS_Instrument_ID

        ---------------------------------------------------
        -- Update intervals for each instrument
        ---------------------------------------------------

        Declare @instrument varchar(64)
        Declare @emslInstrument char(1)
        Declare @tracked tinyint
        Declare @useEUSid tinyint
        Declare @eusInstrumentId Int

        Declare @index int = 0
        Declare @continue tinyint = 1
        Declare @skipInstrument tinyint = 0
        Declare @iteration int = 0

        WHILE @continue = 1
        BEGIN -- <a>
            Set @instrument = NULL
            SELECT TOP 1 @instrument = Instrument,
                         @emslInstrument = EMSL,
                         @tracked = Tracked,
                         @useEUSid = Use_EUS_ID,
                         @eusInstrumentId = EUS_Instrument_ID
            FROM #Tmp_Instruments
            WHERE Seq > @index

            Set @index = @index + 1

            IF @instrument IS NULL
            BEGIN
                Set @continue = 0
            END
            ELSE
            BEGIN -- <b>
                Set @skipInstrument = 0

                If @useEUSid > 0
                Begin
                    If Exists (Select * From #Tmp_EUS_IDs_Processed Where EUS_Instrument_ID = @eusInstrumentId)
                    Begin
                        Set @skipInstrument = 1
                    End
                    Else
                    Begin
                        Insert Into #Tmp_EUS_IDs_Processed (EUS_Instrument_ID)
                        Values (@eusInstrumentId)
                    End
                End

                If @skipInstrument = 0
                Begin -- <c>

                    EXEC UpdateDatasetInterval @instrument, @startDate, @bonm, @message output, @infoOnly=@infoOnly

                    If @updateEMSLInstrumentUsage <> 0 AND (@emslInstrument = 'Y' OR @tracked = 1)
                    Begin -- <d>

                        -- Call UpdateEMSLInstrumentUsageReport for this month, plus optionally previous months (if @instrumentUsageMonthsToUpdate is greater than 1)
                        --
                        Set @iteration = 0
                        While @iteration < @instrumentUsageMonthsToUpdate
                        Begin -- <e>
                            Set @iteration = @iteration + 1

                            If @infoOnly > 0
                            Begin
                                Print 'Call UpdateEMSLInstrumentUsageReport for Instrument ' + @instrument +
                                      ', target month ' + 
                                      Cast(Year(@instrumentUsageMonth) As varchar(12)) + '-' + 
                                      Cast(Month(@instrumentUsageMonth) As varchar(12))
                            End

                            If @useEUSid > 0
                            Begin
                                EXEC UpdateEMSLInstrumentUsageReport '', @eusInstrumentId, @instrumentUsageMonth, @message output, @infoonly=@infoonly
                            End
                            Else
                            Begin
                                EXEC UpdateEMSLInstrumentUsageReport @instrument, 0, @instrumentUsageMonth, @message output, @infoonly=@infoonly
                            End

                            If @infoOnly > 0
                                Print ''

                            Set @instrumentUsageMonth = DateAdd(month, -1, @instrumentUsageMonth)
                        End -- </e>
                    End -- </d>
                    Else
                    Begin
                        If @infoOnly > 0
                        Begin
                            Print 'Skip call to UpdateEMSLInstrumentUsageReport for Instrument ' + @instrument
                            Print ''
                        End
                    End
                End -- </c>
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
