/****** Object:  StoredProcedure [dbo].[add_requested_run_batch_location_scan] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_requested_run_batch_location_scan]
/****************************************************
**
**  Desc:
**      Adds a location scan to T_Requested_Run_Batch_Location_History for one or more requested run batches
**
**  Arguments:
**    @locationId           Location ID (row in in t_material_locations)
**    @scanDate             Scan date/time
**    @batchIdList          Requested run batch IDs (comma separated list)
**    @message              Error message (output); empty string if no error
**    @returnCode           Return code (duplicates the integer returned by this procedure; varchar for compatibility with Postgres error codes)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   bcg
**  Date:   05/19/2023 bcg - Initial version
**          05/23/2023 mem - Add missing error message and additional validation
**          05/24/2023 mem - Update @message if any batch IDs are unrecognized, but continue processing
**          05/24/2023 bcg - Correct table update logic to not store the same value to first_scan_date and last_scan_date
**
*****************************************************/
(
    @locationId int,
    @scanDate datetime,
    @batchIdList varchar(max),
    @message varchar(512) = '' output,
    @returnCode varchar(64) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @useRaiseError tinyint = 1
    Declare @logErrors tinyint = 0
    Declare @matchCount int

    Set @message = ''
    Set @returnCode = ''

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

    Set @locationId  = Coalesce(@locationId, 0)
    Set @scanDate    = Coalesce(@scanDate, GetDate())
    Set @batchIdList = Coalesce(@batchIdList, '')

    If Not Exists (SELECT ID FROM T_Material_Locations WHERE ID = @locationId)
    Begin
        Set @message = 'Location ID not found in T_Material_Locations: ' + Cast(@locationId As varchar(12))
        Set @myError = 50001
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 1)
        Else
            RETURN @myError
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Create temporary table for requests in list
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_BatchIDs (
        BatchIDText varchar(128) NULL,
        Batch_ID int NULL,
        Valid tinyint DEFAULT 0
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary table for batch IDs'
        Set @myError = 50002
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 22)
        Else
            RETURN @myError
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
        Set @myError = 50003
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 23)
        Else
            RETURN @myError
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
        Set @message = 'Batch IDs must be integers, not names; first invalid item: ' + Coalesce(@firstInvalid, '')
        Set @myError = 50004
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 30)
        Else
            RETURN @myError
    End

    ---------------------------------------------------
    -- Check status of supplied batch IDs
    ---------------------------------------------------

    -- Do all batch IDs in list actually exist?
    --
    Set @matchCount = 0
    --
    UPDATE #Tmp_BatchIDs
    SET #Tmp_BatchIDs.Valid = 1
    FROM T_Requested_Run_Batches RRB
    WHERE #Tmp_BatchIDs.Batch_ID = RRB.ID

    SELECT @matchCount = COUNT(*)
    FROM #Tmp_BatchIDs
    WHERE Valid = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed trying to check existence of batch IDs in list'
        Set @myError = 50005
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 24)
        Else
            RETURN @myError
    End

    If @matchCount > 0
    Begin
        Declare @invalidIDs varchar(512) = null

        SELECT @invalidIDs = Coalesce(@invalidIDs + ', ', '') + BatchIDText
        FROM #Tmp_BatchIDs
        WHERE Valid = 0
        ORDER BY BatchIDText

        Set @message = 'Batch ID list contains ' +
                       CASE WHEN CharIndex(',', @invalidIDs) > 0 
                            THEN 'batch IDs that do not exist: ' 
                            ELSE 'a batch ID that does not exist: '
                       END +
                       @invalidIDs

        RAISERROR (@message, 10, 24)

        DELETE FROM #Tmp_BatchIDs
        WHERE Valid = 0

        If Not Exists (SELECT * FROM #Tmp_BatchIDs)
        Begin
            -- No valid Batch IDs remain

            Set @logErrors = 0;
            Set @message = @message + '; did not find any valid Batch IDs';
            Set @myError = 50006
            Set @returnCode = Cast(@myError As varchar(64))

            If @useRaiseError > 0
                RAISERROR (@message, 11, 25)
            Else
                RETURN @myError
        End

        Declare @validIDs varchar(512) = null

        SELECT @validIDs = Coalesce(@validIDs + ', ', '') + BatchIDText
        FROM #Tmp_BatchIDs
        ORDER BY BatchIDText

        Set @message = @message + 
                       '; updating location for Batch ' + 
                       CASE WHEN CharIndex(',', @validIDs) > 0 THEN 'IDs ' ELSE 'ID ' END +
                       @validIDs
    End

    -- Start transaction
    --
    Declare @transName varchar(32) = 'AddBatchLocationScan'

    Begin Transaction @transName

    MERGE T_Requested_Run_Batch_Location_History AS t
    USING (SELECT @locationID AS location_id, batch_id FROM #Tmp_BatchIDs) AS s
    ON ( t.batch_id = s.batch_id AND t.location_id = s.location_id )
    WHEN MATCHED AND (t.first_scan_date < @scanDate OR t.last_scan_date IS NULL OR t.last_scan_date < @scanDate) THEN
        UPDATE SET
            last_scan_date =  CASE
                                -- copy value from first_scan_date to last_scan_date if we will update first_scan_date
                                WHEN t.last_scan_date IS NULL AND @scanDate < t.first_scan_date THEN t.first_scan_date
                                -- update last_scan_date if the value is later than both first_scan_date and last_scan_date (don't allowing storing the same value to both first_scan_date and last_scan_date)
                                WHEN t.first_scan_date < @scanDate AND (t.last_scan_date IS NULL OR t.last_scan_date < @scanDate) THEN @scanDate
                                -- otherwise keep the same value
                                ELSE t.last_scan_date
                              END,
            first_scan_date = CASE
                                -- update first_scan_date since the value is earlier
                                WHEN @scanDate < t.first_scan_date THEN @scanDate
                                -- otherwise keep the same value
                                ELSE t.first_scan_date
                              END
    WHEN NOT MATCHED THEN
        INSERT (batch_id, location_id, first_scan_date)
        VALUES (s.batch_id, s.location_id, @scanDate);

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Merge operation failed while adding/updating batch location history'
        Set @myError = 50007
        Set @returnCode = Cast(@myError As varchar(64))

        If @useRaiseError > 0
            RAISERROR (@message, 11, 26)
        Else
            RETURN @myError
    End

    Commit Transaction @transName

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
            Exec post_log_entry 'Error', @message, 'add_requested_run_batch_location_scan'
    END CATCH

    Set @returnCode = Cast(@myError As varchar(64))
    RETURN @myError

GO
GRANT EXECUTE ON [dbo].[add_requested_run_batch_location_scan] TO [DMS_LCMSNet_User] AS [dbo]
GO
