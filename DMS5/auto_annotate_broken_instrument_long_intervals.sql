/****** Object:  StoredProcedure [dbo].[auto_annotate_broken_instrument_long_intervals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_annotate_broken_instrument_long_intervals]
/****************************************************
**
**  Desc:  Updates the comments for long intervals in table T_Run_Interval
**         to be 'Broken[100%]' for instruments with status 'broken'
**
**  Auth:   mem
**  Date:   05/12/2022 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @targetDate datetime,       -- Date used to determine the target year and month to examine; if null, will examine the previous month
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on
    Set ANSI_PADDING ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @targetMonth int
    Declare @targetYear int

    Declare @monthAndYear varchar(24)
    Declare @intervalDescription varchar(128)

    Declare @continue tinyint
    Declare @updateIntervals tinyint

    Declare @instrumentID int
    Declare @instrumentName varchar(64)
    Declare @runIntervalID int

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'auto_annotate_broken_instrument_long_intervals', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    BEGIN Try

        Set @targetDate = IsNull(@targetDate, DateAdd(Month, -1, GetDate()))
        Set @infoOnly = IsNull(@infoOnly, 1)

        Set @targetMonth = Month(@targetDate)
        SEt @targetYear = Year(@targetDate)

        -- Populate a string with the target month name and year
        Set @monthAndYear = DateName(month, @targetDate) + ' ' + Cast(@targetYear As varchar(12))

        CREATE TABLE #Tmp_BrokenInstruments (
            Instrument_ID int NOT NULL,
            Instrument varchar(64)
        )

        CREATE TABLE #Tmp_IntervalsToUpdate (
            IntervalID Int
        )

        INSERT INTO #Tmp_BrokenInstruments(Instrument_ID, Instrument )
        SELECT Instrument_ID, IN_Name
        FROM T_Instrument_Name
        WHERE IN_status = 'Broken'

        Set @continue = 1
        Set @instrumentID = -1

        While @continue > 0
        Begin -- <a>
            SELECT TOP 1 @instrumentID = Instrument_ID,
                         @instrumentName = Instrument
            FROM #Tmp_BrokenInstruments
            WHERE Instrument_ID > @instrumentID
            ORDER BY Instrument_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin -- <b>
                DELETE FROM #Tmp_IntervalsToUpdate

                INSERT INTO #Tmp_IntervalsToUpdate( IntervalID )
                SELECT ID
                FROM T_Run_Interval
                WHERE Instrument = @instrumentName AND
                      MONTH(Start) = @targetMonth AND
                      YEAR(Start) = @targetYear AND
                      Interval > 20000 AND
                      IsNull(Comment, '') = ''
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @updateIntervals = 0

                    If @infoOnly > 0
                    Begin
                        Set @message = 'No unannotated long intervals were found for instrument ' + @instrumentName + ' in ' + @monthAndYear
                        Print @message
                    End
                End
                Else
                Begin
                    Set @updateIntervals = 1
                End

                Set @runIntervalId = -1

                While @updateIntervals > 0
                Begin -- <c>
                    SELECT TOP 1 @runIntervalID = IntervalID
                    FROM #Tmp_IntervalsToUpdate
                    WHERE IntervalID > @runIntervalID
                    ORDER BY IntervalID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount = 0
                    Begin
                        Set @updateIntervals  = 0
                    End
                    Else
                    Begin -- </d>

                        Set @intervalDescription = 'interval ' + Cast(@runIntervalId As Varchar(12)) + ' as Broken for instrument ' + @instrumentName + ' in ' + @monthAndYear

                        If @infoOnly > 0
                        Begin
                            Print 'Preview: Call add_update_run_interval to annotate ' + @intervalDescription
                        End
                        Else
                        Begin
                            Exec @myError = add_update_run_interval @runIntervalID, 'Broken[100%]', 'update', @message = @message output, @callingUser = 'PNL\msdadmin (auto_annotate_broken_instrument_long_intervals)'

                            If @myError = 0
                            Begin
                                Set @message = 'Annotated ' + @intervalDescription
                                Exec post_log_entry 'Normal', @message, 'auto_annotate_broken_instrument_long_intervals'
                            End
                            Else
                            Begin
                                Set @message = 'Error annotating ' + @intervalDescription
                                Exec post_log_entry 'Error', @message, 'auto_annotate_broken_instrument_long_intervals'
                            End

                        End
                    End -- </d>
                End -- </c>
            End -- </b>
        End -- </a>

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END CATCH

    Return @myError

GO
