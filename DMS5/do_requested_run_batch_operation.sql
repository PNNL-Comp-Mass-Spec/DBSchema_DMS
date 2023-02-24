/****** Object:  StoredProcedure [dbo].[DoRequestedRunBatchOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DoRequestedRunBatchOperation]
/****************************************************
**
**  Desc:
**      Perform operations on requested run batches
**      that only admins are allowed to do
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/12/2006
**          09/20/2006 jds - Added support for Granting High Priority and Denying High Priority for fields Actual_Bath_Priority and Requested_Batch_Priority
**          08/27/2009 grk - Delete batch fixes requested run references in history table
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/25/2017 mem - Remove mode BatchOrder since unused
**          08/01/2017 mem - Use THROW if not authorized
**          08/01/2022 mem - Exit the procedure if @batchID is 0
**          02/10/2023 mem - Call UpdateCachedRequestedRunBatchStats
**
*****************************************************/
(
    @batchID int,
    @mode varchar(12), -- 'LockBatch', 'UnlockBatch', 'delete'; Supported, but unused in July 2017 are 'FreeMembers', 'GrantHiPri', 'DenyHiPri'
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DoRequestedRunBatchOperation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Set @batchID = Coalesce(@batchID, 0)

    If @batchID = 0
    Begin;
        THROW 51000, 'Batch operation tasks are not allowed for Batch 0', 1;
    End;

    ---------------------------------------------------
    -- Is batch in table?
    ---------------------------------------------------

    Declare @batchExists int
    Declare @lock varchar(12)
    set @batchExists = 0
    --
    SELECT @lock = Locked
    FROM T_Requested_Run_Batches
    WHERE ID = @batchID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Failed trying to find batch in batch table'
        RAISERROR (@message, 10, 1)
        return 51007
    End

    set @batchExists = @myRowCount

    ---------------------------------------------------
    -- Lock run order
    ---------------------------------------------------

    If @mode = 'LockBatch'
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

    If @mode = 'UnlockBatch'
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
                set @message = 'Failed trying to unlock table'
                RAISERROR (@message, 10, 1)
                return 51140
            End
        End
        return 0
    End

    ---------------------------------------------------
    -- Remove current member requests from batch
    ---------------------------------------------------

    If @mode = 'FreeMembers' or @mode = 'delete'
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

            Exec UpdateCachedRequestedRunBatchStats @batchID

            If @mode = 'FreeMembers'
            Begin
                return 0
            End
        End
    End

    ---------------------------------------------------
    -- Delete batch
    ---------------------------------------------------

    If @mode = 'delete'
    Begin
        If @lock = 'yes'
        Begin
            set @message = 'Cannot delete locked batch'
            RAISERROR (@message, 10, 1)
            return 51170
        End
        else
        Begin
            DELETE FROM T_Requested_Run_Batches
            WHERE ID = @batchID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                set @message = 'Failed trying to unlock table'
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
            Set Actual_Batch_Priority = 'High'
        WHERE ID = @batchID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Failed trying to set Actual Batch Priority to - High'
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
            Set Actual_Batch_Priority = 'Normal',
                Requested_Batch_Priority = 'Normal'
        WHERE ID = @batchID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Failed trying to set Actual Batch Priority and Requested Batch Priority to - Normal'
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
    End -- mode ''

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    set @message = 'Mode "' + @mode +  '" was unrecognized'
    RAISERROR (@message, 10, 1)
    return 51222

GO
GRANT VIEW DEFINITION ON [dbo].[DoRequestedRunBatchOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoRequestedRunBatchOperation] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoRequestedRunBatchOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoRequestedRunBatchOperation] TO [Limited_Table_Write] AS [dbo]
GO
