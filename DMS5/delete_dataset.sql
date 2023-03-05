/****** Object:  StoredProcedure [dbo].[delete_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_dataset]
/****************************************************
**
**  Desc: Deletes given dataset from the dataset table
**        and all referencing tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/26/2001
**          03/01/2004 grk - added unconsume scheduled run
**          04/07/2006 grk - got rid of dataset list stuff
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2007 grk - Modified to call modified unconsume_scheduled_run (Ticket #446)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          05/08/2009 mem - Now checking T_Dataset_Info
**          12/13/2011 mem - Now passing @callingUser to unconsume_scheduled_run
**                         - Now checking T_Dataset_QC and T_Dataset_ScanTypes
**          02/19/2013 mem - No longer allowing deletion if analysis jobs exist
**          02/21/2013 mem - Updated call to unconsume_scheduled_run to refer to @retainHistory by name
**          05/08/2013 mem - No longer passing @wellplateName and @wellNumber to unconsume_scheduled_run
**          08/31/2016 mem - Delete failed capture jobs for the dataset
**          10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**          01/23/2017 mem - Delete jobs from DMS_Capture.dbo.T_Tasks
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/08/2018 mem - Update T_Dataset_Files
**          09/27/2018 mem - Added parameter @infoOnly
**                         - Now showing the unconsumed requested run
**          09/28/2018 mem - Flag AutoReq requested runs as "To be deleted" instead of "To be marked active"
**          11/16/2018 mem - Delete dataset file info from DMS_Capture.dbo.T_Dataset_Info_XML
**                           Change the default for @infoOnly to 1
**                           Rename the first parameter
**          04/17/2019 mem - Delete rows in T_Cached_Dataset_Instruments
**          11/02/2021 mem - Show the full path to the dataset directory at the console
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @datasetName varchar(128),
    @infoOnly tinyint = 1,
    @message varchar(512)='' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)

    Declare @datasetID int
    Declare @state int

    Declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_dataset', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    Set @datasetName = IsNull(@datasetName, '')
    Set @message = ''

    If @datasetName = ''
    Begin
        Set @msg = '@datasetName parameter is blank; nothing to delete'
        RAISERROR (@msg, 10, 1)
        return 51139
    End

    ---------------------------------------------------
    -- Get the datasetID and current state
    ---------------------------------------------------
    --
    Set @datasetID = 0
    --
    SELECT
        @state = DS_state_ID,
        @datasetID = Dataset_ID
    FROM T_Dataset
    WHERE Dataset_Num = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        Set @msg = 'Could not get Id or state for dataset "' + @datasetName + '"'
        RAISERROR (@msg, 10, 1)
        return 51140
    end
    --
    If @datasetID = 0
    begin
        Set @msg = 'Dataset does not exist "' + @datasetName + '"'
        RAISERROR (@msg, 10, 1)
        return 51141
    end

    ---------------------------------------------------
    -- Get the dataset directory path
    ---------------------------------------------------
    --
    Declare @datasetDirectoryPath varchar(512) = Null

    SELECT @datasetDirectoryPath = Dataset_Folder_Path
    FROM V_Dataset_Folder_Paths
    WHERE Dataset_ID = @datasetID

    If Exists (SELECT * FROM T_Analysis_Job WHERE AJ_datasetID = @datasetID)
    Begin
        Set @msg = 'Cannot delete a dataset with existing analysis jobs'
        RAISERROR (@msg, 10, 1)
        return 51142
    End

    If @infoOnly > 0
    Begin
        SELECT 'To be deleted' AS [Action], *
        FROM T_Dataset_Archive
        WHERE AS_Dataset_ID = @datasetID

        If Exists (SELECT * FROM T_Requested_Run WHERE DatasetID = @datasetID)
        Begin
            SELECT CASE WHEN RDS_Name Like 'AutoReq%'
                        THEN 'To be deleted'
                        ELSE 'To be marked active'
                   End AS [Action], *
            FROM T_Requested_Run
            WHERE DatasetID = @datasetID
        End

        SELECT 'To be deleted' AS [Action], *
        FROM T_Dataset_Info
        WHERE Dataset_ID = @datasetID

        SELECT 'To be deleted' AS [Action], *
        FROM T_Dataset_QC
        WHERE Dataset_ID = @datasetID

        SELECT 'To be deleted' AS [Action], *
        FROM T_Dataset_ScanTypes
        WHERE Dataset_ID = @datasetID

        SELECT 'To be flagged as deleted' AS [Action], *
        FROM T_Dataset_Files
        WHERE Dataset_ID = @datasetID

        If Exists (SELECT * FROM DMS_Capture.dbo.T_Tasks WHERE Dataset_ID = @datasetID AND State = 5)
        Begin
            SELECT 'To be deleted' AS [Action], *
            FROM DMS_Capture.dbo.T_Tasks
            WHERE Dataset_ID = @datasetID And State = 5
        End

        If Exists (SELECT * FROM DMS_Capture.dbo.T_Dataset_Info_XML WHERE Dataset_ID = @datasetID)
        Begin
            SELECT 'To be deleted' AS [Action], *
            FROM DMS_Capture.dbo.T_Dataset_Info_XML
            WHERE Dataset_ID = @datasetID
        End

        SELECT 'To be deleted' AS [Action], Tasks.*
        FROM DMS_Capture.dbo.T_Tasks Tasks
             INNER JOIN DMS_Capture.dbo.T_Tasks_History History
               ON Tasks.Job = History.Job
        WHERE Tasks.Dataset_ID = @datasetID AND
              NOT History.Job IS NULL

        SELECT 'To be deleted' AS [Action], *
        FROM T_Dataset
        WHERE Dataset_ID = @datasetID

        Print 'Directory to remove: ' + @datasetDirectoryPath

        Goto Done
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------

    Declare @transName varchar(32)
    Set @transName = 'delete_dataset'
    begin transaction @transName

    ---------------------------------------------------
    -- Delete any entries for the dataset from the archive table
    ---------------------------------------------------
    --
    DELETE FROM T_Dataset_Archive
    WHERE AS_Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from archive table was unsuccessful for dataset', 10, 1)
        return 51131
    end

    ---------------------------------------------------
    -- Delete any auxiliary info associated with dataset
    ---------------------------------------------------
    --
    exec @result = delete_aux_info 'Dataset', @datasetName, @message output

    if @result <> 0
    begin
        rollback transaction @transName
        Set @msg = 'Delete auxiliary information was unsuccessful for dataset: ' + @message
        RAISERROR (@msg, 10, 1)
        return 51136
    end

    ---------------------------------------------------
    -- Restore any consumed requested runs
    ---------------------------------------------------
    --
    Declare @requestID int = Null

    SELECT @requestID = ID
    FROM T_Requested_Run
    WHERE DatasetID = @datasetID

    exec @result = unconsume_scheduled_run @datasetName, @retainHistory=0, @message=@message output, @callingUser=@callingUser
    if @result <> 0
    begin
        rollback transaction @transName
        Set @msg = 'Unconsume operation was unsuccessful for dataset: ' + @message
        RAISERROR (@msg, 10, 1)
        return 51103
    end

    If Not @requestID Is Null
    Begin
        SELECT 'Request updated; verify this action, especially if the deleted dataset was replaced with an identical, renamed dataset' AS [Comment], *
        FROM T_Requested_Run
        WHERE ID = @requestID
    End
    ---------------------------------------------------
    -- Delete any entries in T_Dataset_Info
    ---------------------------------------------------
    --
    DELETE FROM T_Dataset_Info
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from Dataset Info table was unsuccessful for dataset', 10, 1)
        return 51132
    end

    ---------------------------------------------------
    -- Delete any entries in T_Dataset_QC
    ---------------------------------------------------
    --
    DELETE FROM T_Dataset_QC
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from Dataset QC table was unsuccessful for dataset', 10, 1)
        return 51133
    end

    ---------------------------------------------------
    -- Delete any entries in T_Dataset_ScanTypes
    ---------------------------------------------------
    --
    DELETE FROM T_Dataset_ScanTypes
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from Dataset ScanTypes table was unsuccessful for dataset', 10, 1)
        return 51134
    end

    ---------------------------------------------------
    -- Mark entries in T_Dataset_Files as Deleted
    ---------------------------------------------------
    --
    UPDATE T_Dataset_Files
    SET Deleted = 1
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Delete rows in T_Cached_Dataset_Instruments
    ---------------------------------------------------
    --
    DELETE T_Cached_Dataset_Instruments
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Delete any failed jobs in the DMS_Capture database
    ---------------------------------------------------
    --
    DELETE FROM DMS_Capture.dbo.T_Tasks
    WHERE Dataset_ID = @datasetID AND State = 5
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from DMS_Capture.dbo.T_Tasks was unsuccessful for dataset', 10, 1)
        return 51135
    end

    ---------------------------------------------------
    -- Update log entries in the DMS_Capture database
    ---------------------------------------------------
    --
    UPDATE DMS_Capture.dbo.T_Log_Entries
    SET [Type] = 'ErrorAutoFixed'
    WHERE ([Type] = 'error') AND
          message LIKE '%' + @datasetName + '%'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from DMS_Capture.dbo.T_Tasks was unsuccessful for dataset', 10, 1)
        return 51136
    end

    ---------------------------------------------------
    -- Remove jobs from T_Tasks in DMS_Capture,
    -- but only delete if the capture task job is in T_Tasks_History
    ---------------------------------------------------
    --
    DELETE DMS_Capture.dbo.T_Tasks
    FROM DMS_Capture.dbo.T_Tasks Tasks
         INNER JOIN DMS_Capture.dbo.T_Tasks_History History
           ON Tasks.Job = History.Job
    WHERE Tasks.Dataset_ID = @datasetID AND
          NOT History.Job IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Delete entry from dataset table
    ---------------------------------------------------
    --
    DELETE FROM T_Dataset
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount <> 1
    begin
        rollback transaction @transName
        RAISERROR ('Delete from dataset table was unsuccessful for dataset (RowCount != 1)',
            10, 1)
        return 51137
    end

    -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
    If Len(@callingUser) > 0
    Begin
        Declare @stateID int = 0

        Exec alter_event_log_entry_user 4, @datasetID, @stateID, @callingUser
    End

    commit transaction @transName

    SELECT 'Deleted dataset' AS [Action],
           @datasetID AS Dataset_ID,
           @datasetDirectoryPath AS Dataset_Directory_Path

    Print 'ToDo: delete ' + @datasetDirectoryPath

Done:
    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[delete_dataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_dataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_dataset] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_dataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_dataset] TO [Limited_Table_Write] AS [dbo]
GO
