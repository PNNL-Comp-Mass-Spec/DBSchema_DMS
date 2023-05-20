/****** Object:  StoredProcedure [dbo].[add_requested_run_batch_location_scan] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_requested_run_batch_location_scan]
/****************************************************
**
**  Desc: Adds a location scan for requested run batch
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   bcg
**  Date:   05/19/2023 - initial version
**
*****************************************************/
(
    @locationId int,
    @scanDate datetime,
    @batchIdList varchar(max),                 -- Requested run batch IDs
    @message varchar(512) = '' Output,
    @returnCode tinyint = 1 Output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Declare @useRaiseError tinyint = 1

    Set @message = ''
    Set @useRaiseError = IsNull(@useRaiseError, 1)

    Declare @logErrors tinyint = 0
    Declare @existingBatchGroupID int = Null

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_requested_run_batch_location_scan', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Declare @instrumentGroupToUse varchar(64)
    Declare @userID int = 0
    Declare @matchCount int = 0
    Set @locationId = IsNull(@locationId, 0)
    
    SELECT @matchCount = COUNT(ID)
    FROM T_Material_Locations
    WHERE ID = @locationId

    If @matchCount <> 1
    Begin
        If @useRaiseError > 0
            RAISERROR (@message, 11, 1)
        Else
            Return @myError
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Create temporary table for requests in list
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_BatchIDs (
        BatchIDText varchar(128) NULL,
        Batch_ID [int] NULL,
        Valid [tinyint] DEFAULT 0
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary table for batch IDs'

        If @useRaiseError > 0
            RAISERROR (@message, 11, 22)
        Else
            Return 50002
    End

    ---------------------------------------------------
    -- Populate temporary table from list
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_BatchIDs (BatchIDText)
    SELECT DISTINCT Value
    FROM dbo.parse_delimited_list(@BatchIDList, ',', 'add_requested_run_batch_location_scan')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to populate temporary table for batch IDs'

        If @useRaiseError > 0
            RAISERROR (@message, 11, 23)
        Else
            Return 50003
    End

    ---------------------------------------------------
    -- Convert Batch IDs to integers
    ---------------------------------------------------
    --
    UPDATE #Tmp_BatchIDs
    SET Batch_ID = try_cast(BatchIDText as int)

    If Exists (Select * FROM #Tmp_BatchIDs WHERE Batch_ID Is Null)
    Begin
        Declare @firstInvalid varchar(128)

        SELECT TOP 1 @firstInvalid = BatchIDText
        FROM #Tmp_BatchIDs
        WHERE Batch_ID Is Null


        Set @logErrors = 0
        Set @message = 'Batch IDs must be integers, not names; first invalid item: ' + IsNull(@firstInvalid, '')

        If @useRaiseError > 0
            RAISERROR (@message, 11, 30)
        Else
            Return 50004
    End

    ---------------------------------------------------
    -- Check status of supplied batch IDs
    ---------------------------------------------------
    Declare @count int

    -- Do all batch IDs in list actually exist?
    --
    Set @count = 0
    --
    UPDATE #Tmp_BatchIDs
    SET #Tmp_BatchIDs.Valid = 1
    FROM T_Requested_Run_Batches rrb
    WHERE #Tmp_BatchIDs.Batch_ID = rrb.ID

    SELECT @count = COUNT(*)
    FROM #Tmp_BatchIDs
    WHERE Valid = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed trying to check existence of batch IDs in list'

        If @useRaiseError > 0
            RAISERROR (@message, 11, 24)
        Else
            Return 50005
    End

    If @count <> 0
    Begin

        Declare @invalidIDs varchar(64) = null

        SELECT @invalidIDs = Coalesce(@invalidIDs + ', ', '') + BatchIDText
        FROM #Tmp_BatchIDs
        WHERE Valid = 0

        DELETE FROM #Tmp_BatchIDs WHERE Valid = 0

        Set @logErrors = 0
        Set @message = 'Batch ID list contains batch IDs that do not exist: ' + @invalidIDs

        If @useRaiseError > 0 -- TODO: do not fire the error! Just drop batch IDs that don't exist (amd report them via @message).
            RAISERROR (@message, 11, 25)
        Else
            Return 50006

    End
    
    -- Start transaction
    --
    Declare @transName varchar(32) = 'AddBatchLocationScan'

    Begin transaction @transName

    MERGE T_Requested_Run_Batch_Location_History AS t
    USING (SELECT @locationID AS location_id, batch_id FROM #Tmp_BatchIDs) AS s
    ON ( t.batch_id = s.batch_id AND t.location_id = s.location_id )
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (batch_id, location_id, first_scan_date)
        VALUES (s.batch_id, s.location_id, @scanDate)
    WHEN MATCHED AND (t.first_scan_date < @scanDate OR t.last_scan_date IS NULL OR t.last_scan_date < @scanDate) THEN
        UPDATE 
            SET last_scan_date = CASE
                                     WHEN t.last_scan_date IS NULL AND @scanDate < t.first_scan_date THEN t.first_scan_date
                                     WHEN t.last_scan_date IS NULL OR t.last_scan_date < @scanDate THEN @scanDate
                                     ELSE t.last_scan_date
                                 END,
                first_scan_date = CASE
                                     WHEN @scanDate < t.first_scan_date THEN @scanDate 
                                     ELSE t.first_scan_date 
                                  END;
            
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Merge operation failed while adding updated batch ID locations'

        If @useRaiseError > 0
            RAISERROR (@message, 11, 26)
        Else
            Return 50007
    End

    commit transaction @transName
    
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec post_log_entry 'Error', @message, 'add_requested_run_batch_location_scan'
    END CATCH

    return @myError

GO
