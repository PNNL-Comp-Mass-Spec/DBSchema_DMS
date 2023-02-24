/****** Object:  StoredProcedure [dbo].[GetMonthlyEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetMonthlyEMSLInstrumentUsageReport]
/****************************************************
**
**  Desc:
**    Create a monthly usage report for multiple
**    instruments for given year and month
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/16/2012
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/03/2019 mem - Add support for DMS instruments that share a single eusInstrumentId
**          02/14/2022 mem - Add new columns to temporary table #ZR (to match data returned by GetMonthlyInstrumentUsageReport)
**                         - Add @infoOnly parameter
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @year varchar(12),
    @month varchar(12),
    @message varchar(512) Output,
    @infoOnly tinyint = 0                 -- When 1, show debug information.  When 2, do not actually call GetMonthlyInstrumentUsageReport
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- temp table to hold results
    ---------------------------------------------------

    CREATE TABLE #ZR (
        EMSL_Inst_ID int,
        Instrument varchar(64),
        [Type] varchar(128),
        [Start] datetime,
        [Minutes] int,
        Proposal varchar(32) NULL,
        [Usage] varchar(32) NULL,
        Users varchar(1024) NULL,
        Operator varchar(128) Null,
        Comment varchar(4096) NULL,
        [Year] INT,
        [Month] INT,
        ID INT
    )

    ---------------------------------------------------
    -- temp table to hold list of production instruments
    ---------------------------------------------------

    CREATE TABLE #Tmp_Instruments (
        EntryID int IDENTITY(1,1) NOT NULL,
        Instrument varchar(65)
    )

    ---------------------------------------------------
    -- Temp table to track DMS instruments that share the same EUS ID
    ---------------------------------------------------
    Create Table #Tmp_InstrumentsToProcessByID (
        EUS_Instrument_ID int NOT NULL,
        Instrument varchar(65) NOT NULL
    )

    ---------------------------------------------------
    -- Accumulate data for all instruments, one at a time
    ---------------------------------------------------
    BEGIN TRY

        ---------------------------------------------------
        -- Find production instruments that we need to process by EUS_Instrument_ID
        -- because two (or more) DMS Instruments have the same EUS_Instrument_ID
        ---------------------------------------------------

        INSERT INTO #Tmp_InstrumentsToProcessByID ( EUS_Instrument_ID, Instrument )
        SELECT InstMapping.EUS_Instrument_ID,
               InstName.IN_name
        FROM T_Instrument_Name InstName
             INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
               ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
             INNER JOIN ( SELECT EUS_Instrument_ID
                          FROM T_Instrument_Name InstName
                               INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                                 ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                          GROUP BY EUS_Instrument_ID
                          HAVING Count(*) > 1 ) LookupQ
               ON InstMapping.EUS_Instrument_ID = LookupQ.EUS_Instrument_ID
        WHERE InstName.IN_status = 'active' AND
              InstName.IN_operations_role = 'Production'

        ---------------------------------------------------
        -- Get list of active production instruments
        ---------------------------------------------------

        INSERT INTO #Tmp_Instruments( Instrument )
        SELECT IN_name
        FROM T_Instrument_Name
        WHERE IN_status = 'active' And
              IN_operations_role = 'Production' And
              NOT IN_Name IN ( SELECT Instrument
                               FROM #Tmp_InstrumentsToProcessByID )

        If @infoOnly > 0
        Begin
            SELECT *
            FROM #Tmp_Instruments
            ORDER BY EntryID

            SELECT *
            FROM #Tmp_InstrumentsToProcessByID
            ORDER BY EUS_Instrument_ID
        End

        Declare @instrument varchar(64)
        Declare @entryID int = -1
        Declare @continue tinyint = 1

        ---------------------------------------------------
        -- Get usage data for instruments, by name
        ---------------------------------------------------

        WHILE @continue > 0
        BEGIN -- <a1>

            SELECT TOP 1 @instrument = Instrument,
                         @entryID = EntryID
            FROM #Tmp_Instruments
            WHERE EntryID > @entryID
            ORDER BY EntryID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            BEGIN
                Set @continue = 0
            END
            ELSE
            Begin
                If @infoOnly > 0
                Begin
                    Print 'EXEC GetMonthlyInstrumentUsageReport ' + @instrument + ', 0, ' + @year + ', ' + @month + ', ''report'', @message output'
                End

                If @infoOnly <= 1
                Begin
                    INSERT INTO #ZR (Instrument, EMSL_Inst_ID, [Start], Type, [Minutes], Proposal, Usage, Users, Operator, Comment, [Year], [Month], ID)
                    EXEC GetMonthlyInstrumentUsageReport @instrument, 0, @year, @month, 'report', @message output
                End


            END
        END -- </a1>

        ---------------------------------------------------
        -- Get usage data for instruments, by EUS Instrument ID
        ---------------------------------------------------

        Declare @eusInstrumentId As Int = -1
        Set @continue = 1

        WHILE @continue > 0
        BEGIN -- <a2>

            SELECT TOP 1 @instrument = Instrument,
                         @eusInstrumentId = EUS_Instrument_ID
            FROM #Tmp_InstrumentsToProcessByID
            WHERE EUS_Instrument_ID > @eusInstrumentId
            ORDER BY EUS_Instrument_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            BEGIN
                Set @continue = 0
            END
            ELSE
            Begin
                If @infoOnly > 0
                Begin
                    Print 'EXEC GetMonthlyInstrumentUsageReport '''', ' + Cast( @eusInstrumentId As Varchar(12)) + ', ' + @year + ', ' + @month + ', ''report'', @message output'
                End

                If @infoOnly <= 1
                Begin
                    INSERT INTO #ZR (Instrument, EMSL_Inst_ID, [Start], Type, [Minutes], Proposal, Usage, Users, Operator, Comment, [Year], [Month], ID)
                    EXEC GetMonthlyInstrumentUsageReport '', @eusInstrumentId, @year, @month, 'report', @message Output
                End
            END
        END -- </a2>

        ---------------------------------------------------
        -- Return accumulated report
        ---------------------------------------------------

        SELECT
            EMSL_Inst_ID,
            Instrument AS DMS_Instrument,
            [Type],
            CONVERT(varchar(24), [Start], 100) AS [Start],
            [Minutes],
            Proposal,
            Usage,
            Users,
            Operator,
            Comment
          FROM #ZR

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'GetMonthlyEMSLInstrumentUsageReport'
    END CATCH

    If @infoOnly <> 0 and @myError <> 0
        Print @message

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetMonthlyEMSLInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
