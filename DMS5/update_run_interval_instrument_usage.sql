/****** Object:  StoredProcedure [dbo].[update_run_interval_instrument_usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_run_interval_instrument_usage]
/****************************************************
**
**  Desc:   Determines the instrument associated with the given run interval ID
**          then calls update_dataset_interval_for_multiple_instruments
**          (which calls update_dataset_interval and update_emsl_instrument_usage_report)
**
**  Auth:   mem
**  Date:   02/15/2022 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @runIntervalId int,
    @daysToProcess Int = 90,
    @infoOnly tinyint = 0,
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @instrumentName varchar(64)
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @runIntervalId = IsNull(@runIntervalId, -1)
    Set @daysToProcess = IsNull(@daysToProcess, 90)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    Set @callingUser = IsNull(@callingUser, '')
    if @callingUser = ''
        Set @callingUser = suser_sname()

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_run_interval_instrument_usage', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    IF @runIntervalId < 0
    Begin
        Set @message = 'Invalid run interval ID: ' + Cast(@runIntervalId as varchar(9))
        RAISERROR (@message, 11, 10)
        Goto Done
    End

    -- Lookup the instrument associated with the run interval
    SELECT @instrumentName = Instrument
    FROM T_Run_Interval
    WHERE ID = @runIntervalId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0 OR Coalesce(@instrumentName, '') = ''
    Begin
        Set @message = 'Run Interval ID ' + Cast(@runIntervalId As varchar(12)) + ' does not exist; cannot determine the instrument'
        RAISERROR (@message, 11, 16)
    End

    Set @logErrors = 1

    If @infoOnly = 0
    Begin
        Set @message = 'Calling update_dataset_interval_for_multiple_instruments for instrument ' + @instrumentName + ', calling user ' + @callingUser
        Exec post_log_entry 'Info', @message, 'update_run_interval_instrument_usage'
    End

    Exec update_dataset_interval_for_multiple_instruments @daysToProcess = @daysToProcess,
                                                     @updateEMSLInstrumentUsage = 1,
                                                     @infoOnly = @infoOnly,
                                                     @instrumentsToProcess = @instrumentName,
                                                     @message = @message output

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec post_log_entry 'Error', @message, 'update_run_interval_instrument_usage'
    END CATCH

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_run_interval_instrument_usage] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_run_interval_instrument_usage] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_run_interval_instrument_usage] TO [DMS2_SP_User] AS [dbo]
GO
