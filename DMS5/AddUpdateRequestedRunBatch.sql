/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRunBatch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateRequestedRunBatch]
/****************************************************
**
**  Desc: Adds new or edits existing requested run batch
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/11/2006 - initial version
**          09/15/2006 jds - Added @requestedBatchPriority, @actualBathPriority, @requestedCompletionDate, @justificationHighPriority, and @comment
**          11/04/2006 grk - added @requestedInstrument
**          12/03/2009 grk - checking for presence of @justificationHighPriority If priority is high
**          05/05/2010 mem - Now calling AutoResolveNameToPRN to check If @operPRN contains a person's real name rather than their username
**          08/04/2010 grk - try-catch for error handling
**          08/27/2010 mem - Now auto-switching @requestedInstrument to be instrument group instead of instrument name
**                         - Expanded @requestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**          05/14/2013 mem - Expanded @requestedCompletionDate to varchar(32) to support long dates of the form 'Jan 29 2010 12:00:00:000AM'
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/23/2017 mem - Check for @requestedRunList containing request names instead of IDs
**          08/01/2017 mem - Use THROW If not authorized
**          08/18/2017 mem - Log additional errors to T_Log_Entries
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          05/29/2021 mem - Refactor validation code into new stored procedure
**
*****************************************************/
(
    @id int output,                                 -- Batch ID to update if @mode is 'update'; otherwise, the ID of the newly created batch
    @name varchar(50),
    @description varchar(256),
    @requestedRunList varchar(4000),                -- Requested run IDs
    @ownerPRN varchar(64),
    @requestedBatchPriority varchar(24),
    @requestedCompletionDate varchar(32),
    @justificationHighPriority varchar(512),
    @requestedInstrument varchar(64),               -- Will typically contain an instrument group, not an instrument name; could also contain "(lookup)"
    @comment varchar(512),
    @mode varchar(12) = 'add',                      -- or 'update' or 'PreviewAdd'
    @message varchar(512) Output,
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @useRaiseError = IsNull(@useRaiseError, 1)

    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateRequestedRunBatch', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Declare @instrumentGroup varchar(64)
    Declare @userID int = 0
    
    Exec @myError = ValidateRequestedRunBatchParams
            @id,
            @name,
            @description,
            @ownerPRN,
            @requestedBatchPriority,
            @requestedCompletionDate,
            @justificationHighPriority,
            @requestedInstrument,           -- Will typically contain an instrument group, not an instrument name
            @comment,
            @mode,
            @instrumentGroup = @instrumentGroup output,
            @userID = @userID output,
            @message = @message output

    If @myError > 0
    Begin
        If @useRaiseError > 0
            RAISERROR (@message, 11, 1)
        Else
            Return @myError
    End

    If Len(IsNull(@requestedCompletionDate, '')) = 0
    Begin
        Set @requestedCompletionDate = null
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Create temporary table for requests in list
    ---------------------------------------------------
    --
    CREATE TABLE #XR (
        RequestIDText varchar(128) NULL,
        Request_ID [int] NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to create temporary table for requests'
        RAISERROR (@message, 11, 22)
    end

    ---------------------------------------------------
    -- Populate temporary table from list
    ---------------------------------------------------
    --
    INSERT INTO #XR (RequestIDText)
    SELECT Item
    FROM MakeTableFromList(@RequestedRunList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to populate temporary table for requests'
        RAISERROR (@message, 11, 23)
    end

    ---------------------------------------------------
    -- Convert Request IDs to integers
    ---------------------------------------------------
    --
    UPDATE #XR
    SET Request_ID = try_cast(RequestIDText as int)

    If Exists (Select * FROM #XR WHERE Request_ID Is Null)
    Begin
        Declare @firstInvalid varchar(128)

        SELECT TOP 1 @firstInvalid = RequestIDText
        FROM #XR
        WHERE Request_ID Is Null

        Set @logErrors = 0
        Set @message = 'Requested runs must be integers, not names; first invalid item: ' + IsNull(@firstInvalid, '')
        RAISERROR (@message, 11, 30)
    End

    ---------------------------------------------------
    -- check status of prospective member requests
    ---------------------------------------------------
    declare @count int

    -- do all requests in list actually exist?
    --
    set @count = 0
    --
    SELECT @count = count(*)
    FROM #XR
    WHERE NOT (Request_ID IN
    (
        SELECT ID
        FROM T_Requested_Run)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed trying to check existence of requests in list'
        RAISERROR (@message, 11, 24)
    end

    if @count <> 0
    begin

        Declare @invalidIDs varchar(64) = null

        SELECT @invalidIDs = Coalesce(@invalidIDs + ', ', '') + RequestIDText
        FROM #XR
        WHERE NOT (Request_ID IN
        (
            SELECT ID
            FROM T_Requested_Run)
        )

        Set @logErrors = 0
        set @message = 'Requested run list contains requests that do not exist: ' + @invalidIDs
        RAISERROR (@message, 11, 25)

    end

    -- start transaction
    --
    declare @transName varchar(32)
    set @transName = 'UpdateRequestState'
    begin transaction @transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_Requested_Run_Batches (
            Batch,
            Description,
            Owner,
            Locked,
            Requested_Batch_Priority,
            Actual_Batch_Priority,
            Requested_Completion_Date,
            Justification_for_High_Priority,
            Requested_Instrument,
            Comment
        ) VALUES (
            @Name,
            @Description,
            @userID,
            'No',
            @RequestedBatchPriority,
            'Normal',
            @RequestedCompletionDate,
            @JustificationHighPriority,
            @InstrumentGroup,
            @Comment
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Insert operation failed'
            RAISERROR (@message, 11, 26)
        end

        -- return ID of newly created entry
        --
        Set @ID = SCOPE_IDENTITY()

        -- As a precaution, query T_Requested_Run_Batches using Batch name to make sure we have the correct Exp_ID
        Declare @BatchIDConfirm int = 0

        SELECT @BatchIDConfirm = ID
        FROM T_Requested_Run_Batches
        WHERE Batch = @Name

        If @ID <> IsNull(@BatchIDConfirm, @ID)
        Begin
            Declare @DebugMsg varchar(512)
            Set @DebugMsg = 'Warning: Inconsistent identity values when adding batch ' + @Name + ': Found ID ' +
                            Cast(@BatchIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                            Cast(@ID as varchar(12))

            exec postlogentry 'Error', @DebugMsg, 'AddUpdateRequestedRunBatch'

            Set @ID = @BatchIDConfirm
        End


  end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0
        --
        UPDATE T_Requested_Run_Batches
        SET Batch = @Name,
            Description = @Description,
            Owner = @userID,
            Requested_Batch_Priority = @RequestedBatchPriority,
            Requested_Completion_Date = @RequestedCompletionDate,
            Justification_for_High_Priority = @JustificationHighPriority,
            Requested_Instrument = @InstrumentGroup,
            Comment = @Comment
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@message, 11, 27)
        end
    end -- update mode

  ---------------------------------------------------
  -- update member requests
  ---------------------------------------------------

      if @Mode = 'add' OR @Mode = 'update'
    begin
        -- remove any existing references to the batch
        -- from requested runs
        --
        UPDATE T_Requested_Run
        SET RDS_BatchID = 0
        WHERE RDS_BatchID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Failed trying to remove batch reference from existing requests'
            RAISERROR (@message, 11, 28)
        end

        -- add reference to this batch to the requests in the list
        --
         UPDATE T_Requested_Run
        SET RDS_BatchID = @ID
        WHERE ID IN (Select Request_ID from #XR)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Failed trying to add batch reference to requests'
            RAISERROR (@message, 11, 29)
        end
    end

    commit transaction @transName

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec PostLogEntry 'Error', @message, 'AddUpdateRequestedRunBatch'
    END CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRunBatch] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRunBatch] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRunBatch] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRunBatch] TO [Limited_Table_Write] AS [dbo]
GO
