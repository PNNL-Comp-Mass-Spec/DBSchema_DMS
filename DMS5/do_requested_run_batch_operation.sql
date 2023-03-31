/****** Object:  StoredProcedure [dbo].[do_requested_run_batch_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_requested_run_batch_operation]
/****************************************************
**
**  Desc:
**      Lock, unlock, or delete a requested run batch
**
**  Auth:   grk
**  Date:   01/12/2006
**          09/20/2006 jds - Added support for Granting High Priority and Denying High Priority for fields Actual_Bath_Priority and Requested_Batch_Priority
**          08/27/2009 grk - Delete batch fixes requested run references in history table
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/25/2017 mem - Remove mode BatchOrder since unused
**          08/01/2017 mem - Use THROW if not authorized
**          08/01/2022 mem - Exit the procedure if @batchID is 0
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/31/2023 mem - When deleting a batch, archive it in T_Deleted_Requested_Run_Batch
**
*****************************************************/
(
    @batchID int,
    @mode varchar(12),  -- 'LockBatch', 'UnlockBatch', 'Lock', 'Unlock', 'Delete'; Supported, but unused modes (as of July 2017): 'FreeMembers', 'GrantHiPri', 'DenyHiPri'
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_requested_run_batch_operation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Set @batchID = Coalesce(@batchID, 0)
    Set @mode = Coalesce(@mode, '')

    If @batchID = 0
    Begin;
        THROW 51000, 'Batch operation tasks are not allowed for Batch 0', 1;
    End;

    ---------------------------------------------------
    -- Is batch in table?
    ---------------------------------------------------

    Declare @batchExists int = 0
    Declare @lock varchar(12)
    
    SELECT @lock = Locked
    FROM T_Requested_Run_Batches
    WHERE ID = @batchID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        set @message = 'Failed trying to find batch in batch table'
        RAISERROR (@message, 10, 1)
        return 51007
    End

    Set @batchExists = @myRowCount

    ---------------------------------------------------
    -- Lock run order
    ---------------------------------------------------

    If @mode IN ('LockBatch', 'Lock')
    Begin
        If @batchExists > 0
        Begin
            UPDATE T_Requested_Run_Batches
            SET Locked = 'Yes'
            WHERE ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                set @message = 'Failed trying to lock batch'
                RAISERROR (@message, 10, 1)
                return 51140
            End
        End
        return 0
    End

    ---------------------------------------------------
    -- Unlock run order
    ---------------------------------------------------

    If @mode IN ('UnlockBatch', 'Unlock')
    Begin
        If @batchExists > 0
        Begin
            UPDATE T_Requested_Run_Batches
            SET Locked = 'No'
            WHERE ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                set @message = 'Failed trying to unlock batch'
                RAISERROR (@message, 10, 1)
                return 51140
            End
        End
        return 0
    End

    ---------------------------------------------------
    -- Remove current member requests from batch
    ---------------------------------------------------

    If @mode = 'FreeMembers' or @mode = 'Delete'
    Begin
        If @lock = 'yes'
        Begin
            set @message = 'Cannot remove member requests of locked batch'
            RAISERROR (@message, 10, 1)
            return 51170
        End
        Else
        Begin
            UPDATE T_Requested_Run
            SET RDS_BatchID = 0
            WHERE RDS_BatchID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                set @message = 'Failed to remove member requests of batch from main table'
                RAISERROR (@message, 10, 1)
                return 51001
            End

            ---------------------------------------------------
            -- Update stats in T_Cached_Requested_Run_Batch_Stats
            ---------------------------------------------------

            Exec update_cached_requested_run_batch_stats @batchID

            If @mode = 'FreeMembers'
            Begin
                return 0
            End
        End
    End

    ---------------------------------------------------
    -- Delete batch
    ---------------------------------------------------

    If @mode = 'Delete'
    Begin
        If @lock = 'yes'
        Begin
            set @message = 'Cannot delete locked batch'
            RAISERROR (@message, 10, 1)
            return 51170
        End
        Else
        Begin
            INSERT INTO T_Deleted_Requested_Run_Batch (Batch_ID, Batch, Description, Owner_User_ID, Created, Locked, 
                                                       Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority, 
                                                       Requested_Completion_Date, Justification_for_High_Priority, Comment, 
                                                       Requested_Instrument_Group, Batch_Group_ID, Batch_Group_Order)
            SELECT ID, Batch, Description, Owner, Created, Locked, 
                   Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority, 
                   Requested_Completion_Date, Justification_for_High_Priority, Comment, 
                   Requested_Instrument, Batch_Group_ID, Batch_Group_Order
            FROM T_Requested_Run_Batches
            WHERE ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            DELETE FROM T_Requested_Run_Batches
            WHERE ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                set @message = 'Failed trying to delete batch'
                RAISERROR (@message, 10, 1)
                return 51140
            End
            return 0
        End
    End


    ---------------------------------------------------
    -- Grant High Priority
    ---------------------------------------------------

    If @mode = 'GrantHiPri'
    Begin
        UPDATE T_Requested_Run_Batches
        SET Actual_Batch_Priority = 'High'
        WHERE ID = @batchID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Failed trying to set Actual Batch Priority to High'
            RAISERROR (@message, 10, 1)
            return 51145
        End
        return 0
    End


    ---------------------------------------------------
    -- Deny High Priority
    ---------------------------------------------------

    If @mode = 'DenyHiPri'
    Begin
        UPDATE T_Requested_Run_Batches
        SET Actual_Batch_Priority = 'Normal',
            Requested_Batch_Priority = 'Normal'
        WHERE ID = @batchID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Failed trying to set Actual Batch Priority and Requested Batch Priority to Normal'
            RAISERROR (@message, 10, 1)
            return 51150
        End
        return 0
    End


    ---------------------------------------------------
    -- Check for invalid mode
    ---------------------------------------------------

    If @mode = ''
    Begin
        return 0
    End

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    Set @message = 'Mode "' + @mode +  '" was unrecognized'
    RAISERROR (@message, 10, 1)
    return 51222

GO
GRANT VIEW DEFINITION ON [dbo].[do_requested_run_batch_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_requested_run_batch_operation] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_requested_run_batch_operation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_requested_run_batch_operation] TO [Limited_Table_Write] AS [dbo]
GO
