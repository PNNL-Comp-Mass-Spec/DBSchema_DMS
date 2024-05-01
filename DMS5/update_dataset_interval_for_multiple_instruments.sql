/****** Object:  StoredProcedure [dbo].[update_dataset_interval_for_multiple_instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dataset_interval_for_multiple_instruments]
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
**          03/21/2012 grk - Added call to update_emsl_instrument_usage_report
**          03/22/2012 mem - Added parameter @updateEMSLInstrumentUsage
**          03/26/2012 grk - Added call to update_emsl_instrument_usage_report for previous month
**          03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**          03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - modified algorithm
**          08/02/2012 mem - Updated @daysToProcess to default to 60 days instead of 30 days
**          09/18/2012 grk - Only do EMSL instrument updates for EMSL instruments
**          10/06/2012 grk - Removed update of EMSL usage report for previous month
**          03/12/2014 grk - Added processing for "tracked" instruments (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/10/2017 mem - Add parameter @instrumentsToProcess
**          04/11/2017 mem - Now passing @infoOnly to update_emsl_instrument_usage_report
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass @eusInstrumentId to update_emsl_instrument_usage_report for select instruments
**          01/28/2022 mem - Call update_emsl_instrument_usage_report for both the current month, plus also previous months if @daysToProcess is greater than 15
**          02/15/2022 mem - Fix major bug decrementing @instrumentUsageMonth when processing multiple instruments
**                         - Add missing Order By clause
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/21/2023 mem - Look for both 'Y' and '1' when examining the eus_primary_instrument flag (aka EMSL_Primary_Instrument)
**          04/30/2024 mem - Update the message shown when @infoOnly is 1 and update_emsl_instrument_usage_report is not called
**
*****************************************************/
(
    @daysToProcess int = 60,                  -- Also affects whether update_emsl_instrument_usage_report is called for previous months
    @updateEMSLInstrumentUsage tinyint = 1,
    @infoOnly tinyint = 0,
    @instrumentsToProcess varchar(255) = '',
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_dataset_interval_for_multiple_instruments', @raiseError = 1
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
    Declare @currentInstrumentUsageMonth DATETIME

    -- Update instrument usage for the current month, plus possibly the last few months, depending on @daysToProcess
    -- For example, if @daysToProcess is 60, will call update_emsl_instrument_usage_report for this month plus the last two months
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
        Entry_ID int IDENTITY(1,1) NOT NULL,
        Instrument varchar(65),
        EMSL_Primary_Instrument char(1),
        Tracked tinyint,
        EUS_Instrument_ID int Null,
        Use_EUS_ID tinyint Not Null
    )

    CREATE TABLE #Tmp_InstrumentFilter (
        Instrument varchar(65)
    )

    CREATE TABLE #Tmp_EUS_IDs_Processed (
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
            FROM dbo.parse_delimited_list ( @instrumentsToProcess, ',',
                   'update_dataset_interval_for_multiple_instruments' )
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount


            INSERT INTO #Tmp_Instruments( Instrument,
                                          EMSL_Primary_Instrument,
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT InstList.[Name],
                   InstList.EUS_Primary_Instrument AS EMSL_Primary_Instrument,
                   InstList.Tracked,
                   InstList.EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked InstList
                 INNER JOIN #Tmp_InstrumentFilter InstFilter
                   ON InstList.[Name] = InstFilter.Instrument
            ORDER BY IsNull(InstList.EUS_Instrument_ID, 0), InstList.[Name]
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount

        End
        Else
        Begin

            ---------------------------------------------------
            -- Get list of tracked instruments
            ---------------------------------------------------

            INSERT INTO #Tmp_Instruments( Instrument,
                                          EMSL_Primary_Instrument,
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT [Name],
                   EUS_Primary_Instrument AS EMSL_Primary_Instrument,
                   Tracked,
                   EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked
            ORDER BY IsNull(EUS_Instrument_ID, 0), [Name]
            --
            SELECT @myError = @@Error, @myRowCount = @@RowCount

        End

        ---------------------------------------------------
        -- Flag instruments where we need to use EUS instrument ID
        -- instead of instrument name when calling update_emsl_instrument_usage_report
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


        If @infoOnly > 0
        Begin
            SELECT *
            FROM #Tmp_Instruments
            ORDER By Instrument
        End

        ---------------------------------------------------
        -- Update intervals for each instrument
        ---------------------------------------------------

        Declare @instrument varchar(64)
        Declare @emslInstrument char(1)
        Declare @tracked tinyint
        Declare @useEUSid tinyint
        Declare @eusInstrumentId Int

        Declare @entryID int = 0
        Declare @continue tinyint = 1
        Declare @skipInstrument tinyint = 0
        Declare @iteration int = 0

        WHILE @continue = 1
        BEGIN -- <a>
            Set @instrument = NULL
            SELECT TOP 1 @instrument = Instrument,
                         @emslInstrument = EMSL_Primary_Instrument,
                         @tracked = Tracked,
                         @useEUSid = Use_EUS_ID,
                         @eusInstrumentId = EUS_Instrument_ID,
                         @entryID = Entry_ID
            FROM #Tmp_Instruments
            WHERE Entry_ID > @entryID
            ORDER BY Entry_ID

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

                    If @infoOnly >= 2
                    Begin
                        Print 'EXEC update_dataset_interval ' + @instrument + ', ' + Cast(@startDate As Varchar(16)) + ', ' + Cast(@bonm As Varchar(16)) + ', @message output, @infoOnly=@infoOnly'
                    End
                    Else
                    Begin
                        EXEC update_dataset_interval @instrument, @startDate, @bonm, @message output, @infoOnly=@infoOnly
                    End

                    -- Only call update_emsl_instrument_usage_report if the instrument is an "EUS Primary Instrument" or if T_Instrument_Name has the Tracking flag enabled
                    If @updateEMSLInstrumentUsage <> 0 AND (@emslInstrument IN ('Y', '1') OR @tracked = 1)
                    Begin -- <d>

                        -- Call update_emsl_instrument_usage_report for this month, plus optionally previous months (if @instrumentUsageMonthsToUpdate is greater than 1)
                        --
                        Set @iteration = 0
                        Set @currentInstrumentUsageMonth = @InstrumentUsageMonth

                        While @iteration < @instrumentUsageMonthsToUpdate
                        Begin -- <e>
                            Set @iteration = @iteration + 1

                            If @infoOnly > 0
                            Begin
                                Print 'Call update_emsl_instrument_usage_report for Instrument ' + @instrument +
                                      ', target month ' +
                                      Cast(Year(@currentInstrumentUsageMonth) As varchar(12)) + '-' +
                                      Cast(Month(@currentInstrumentUsageMonth) As varchar(12))
                            End

                            If @infoOnly <= 1
                            Begin
                                If @useEUSid > 0
                                Begin
                                    EXEC update_emsl_instrument_usage_report '', @eusInstrumentId, @currentInstrumentUsageMonth, @message output, @infoonly=@infoonly
                                End
                                Else
                                Begin
                                    EXEC update_emsl_instrument_usage_report @instrument, 0, @currentInstrumentUsageMonth, @message output, @infoonly=@infoonly
                                End
                            End

                            If @infoOnly > 0
                                Print ''

                            Set @currentInstrumentUsageMonth = DateAdd(month, -1, @currentInstrumentUsageMonth)
                        End -- </e>
                    End -- </d>
                    Else
                    Begin
                        If @infoOnly > 0
                        Begin
                            If @updateEMSLInstrumentUsage = 0
                                Print 'Skip call to update_emsl_instrument_usage_report for instrument ' + @instrument + ' (since @updateEMSLInstrumentUsage is 0)'
                            Else
                                Print 'Skip call to update_emsl_instrument_usage_report for Instrument ' + @instrument + ' (since it is not an EUS Primary Instrument and the Tracked flag is 0)'

                            Print ''
                        End
                    End
                End -- </c>
            END  -- </b>
        END -- </a>

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_dataset_interval_for_multiple_instruments'

    END CATCH

    If @infoOnly <> 0 and @myError <> 0
        Print @message

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dataset_interval_for_multiple_instruments] TO [DDL_Viewer] AS [dbo]
GO
