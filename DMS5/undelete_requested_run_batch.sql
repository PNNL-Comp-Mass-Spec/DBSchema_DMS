/****** Object:  StoredProcedure [dbo].[undelete_requested_run_batch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[undelete_requested_run_batch]
/****************************************************
**
**  Desc:
**      Restore a deleted requested run batch
**
**  Auth:   mem
**  Date:   03/31/2023 mem - Initial version
**          01/19/2024 mem - Remove reference to deprecated column Requested_Instrument when copying data from T_Deleted_Requested_Run_Batch to T_Requested_Run_Batches
**
*****************************************************/
(
    @batchID int = 0,                     -- Requested run batch ID to restore
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @entryID int
    Declare @batchGroupID int

    Declare @deletedBatchGroupEntryID int = 0

    Set @message = ''
    Set @infoOnly = Coalesce(@infoOnly, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'undelete_requested_run_batch', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the requested run ID
    ---------------------------------------------------
    --
    If Coalesce(@batchID, 0) = 0
    Begin
        Set @message = '@batchID is 0; nothing to do'
        goto Done
    End

    -- Verify that the deleted requested run exists, and lookup the batch ID and EUS person ID
    --
    SELECT TOP 1 @entryID = Entry_ID,
                 @batchGroupID = Batch_Group_ID
    FROM dbo.T_Deleted_Requested_Run_Batch
    WHERE Batch_ID = @batchID
    ORDER BY Entry_Id DESC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Requested Run Batch ID ' + Cast(@batchID as varchar(9)) + ' not found in T_Deleted_Requested_Run_Batch; unable to restore'
        print @message
        goto Done
    End

    ---------------------------------------------------
    -- Make sure the requested run batch does not already exist
    ---------------------------------------------------

    If Exists (SELECT ID FROM T_Requested_Run_Batches WHERE ID = @batchID)
    Begin
        Set @message = 'Requested Run Batch ID ' + Cast(@batchID as varchar(9)) + ' already exists in T_Requested_Run_Batches; unable to undelete'
        print @message
        goto Done
    End

    If @infoOnly > 0
    Begin
        Set @message = 'Would restore requested run Batch ID ' + Cast(@batchID as varchar(9)) + ' by copying Entry_ID ' + Cast(@entryID as varchar(9)) + ' from T_Deleted_Requested_Run_Batch to T_Requested_Run_Batches';
        print @message
        goto Done
    End

    ---------------------------------------------------
    -- See if the deleted requested run batch references a deleted batch group
    ---------------------------------------------------

    If Coalesce(@batchGroupID, 0) > 0 And Not Exists (Select Batch_Group_ID From T_Requested_Run_Batch_Group Where Batch_Group_ID = @batchGroupID)
    Begin
        -- Need to undelete the batch group
        SELECT TOP 1 @deletedBatchGroupEntryID = Entry_ID
        FROM T_Deleted_Requested_Run_Batch_Group
        WHERE Batch_Group_ID = @batchGroupID
        ORDER BY Entry_ID DESC;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Requested run batch ' + Cast(@batchID as varchar(9)) + ', ' +
                            'refers to batch group ' + Cast(@batchGroupID as varchar(9)) + ', ' +
                            'which does not exist and cannot be restored from T_Deleted_Requested_Run_Batch_Group; ' +
                            'see entry ' + Cast(@entryID as varchar(9)) + ' in T_Deleted_Requested_Run_Batch';
            print @message
            goto Done
        End
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'undelete_requested_run_batch'
    begin transaction @transName

    If @deletedBatchGroupEntryID > 0
    Begin
        ---------------------------------------------------
        -- Add the deleted requested run batch group to T_Requested_Run_Batch_Group
        ---------------------------------------------------

        Set IDENTITY_INSERT T_Requested_Run_Batch_Group ON;

        INSERT INTO T_Requested_Run_Batch_Group (Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created)
        SELECT Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created
        FROM T_Deleted_Requested_Run_Batch_Group
        WHERE Entry_ID = @deletedBatchGroupEntryID

        Set IDENTITY_INSERT T_Requested_Run_Batch_Group OFF;
    End

    ---------------------------------------------------
    -- Add the deleted requested run batch to T_Requested_Run_Batches
    ---------------------------------------------------

    Set IDENTITY_INSERT T_Requested_Run_Batches ON;

    INSERT INTO T_Requested_Run_Batches (
            ID, Batch, Description, Owner, Created, Locked,
            Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
            Requested_Completion_Date, Justification_for_High_Priority, Comment,
            -- Deprecated in January 2024
            -- Requested_Instrument, 
            Batch_Group_ID, Batch_Group_Order
        )
    SELECT Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
           Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
           Requested_Completion_Date, Justification_for_High_Priority, Comment,
           -- Requested_Instrument_Group, 
           Batch_Group_ID, Batch_Group_Order
    FROM T_Deleted_Requested_Run_Batch
    WHERE Entry_ID = @entryID

    Set IDENTITY_INSERT T_Requested_Run_Batches OFF;

    commit transaction @transName

    Set @message = 'Restored requested run batch ID ' + Cast(@batchID as varchar(9))
    print @message

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    Exec update_cached_requested_run_batch_stats @batchID

    ---------------------------------------------------
    -- Complete
    ---------------------------------------------------

Done:
    Return @myError

GO
