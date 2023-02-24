/****** Object:  StoredProcedure [dbo].[UpdateRunIntervalInstrumentUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateRunIntervalInstrumentUsage]
/****************************************************
**
**  Desc:   Determines the instrument associated with the given run interval ID
**          then calls UpdateDatasetIntervalForMultipleInstruments
**          (which calls UpdateDatasetInterval and UpdateEMSLInstrumentUsageReport)
**
**  Auth:   mem
**  Date:   02/15/2022 mem - Initial version
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
    Exec @authorized = VerifySPAuthorized 'UpdateRunIntervalInstrumentUsage', @raiseError = 1
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
        Set @message = 'Calling UpdateDatasetIntervalForMultipleInstruments for instrument ' + @instrumentName + ', calling user ' + @callingUser
        Exec PostLogEntry 'Info', @message, 'UpdateRunIntervalInstrumentUsage'
    End

    Exec UpdateDatasetIntervalForMultipleInstruments @daysToProcess = @daysToProcess,
                                                     @updateEMSLInstrumentUsage = 1,
                                                     @infoOnly = @infoOnly,
                                                     @instrumentsToProcess = @instrumentName,
                                                     @message = @message output

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec PostLogEntry 'Error', @message, 'UpdateRunIntervalInstrumentUsage'
    END CATCH

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRunIntervalInstrumentUsage] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRunIntervalInstrumentUsage] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRunIntervalInstrumentUsage] TO [DMS2_SP_User] AS [dbo]
GO
