/****** Object:  StoredProcedure [dbo].[do_requested_run_batch_group_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_requested_run_batch_group_operation]
/****************************************************
**
**  Desc:
**      Delete a requested run batch group
**
**  Auth:   mem
**  Date:   03/31/2023 mem - Initial version
**
*****************************************************/
(
    @batchGroupID int,
    @mode varchar(12),  -- 'Delete'
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
    Exec @authorized = verify_sp_authorized 'do_requested_run_batch_group_operation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Set @batchGroupID = Coalesce(@batchGroupID, 0)
    Set @mode = Coalesce(@mode, '')

    If @batchGroupID < 1
    Begin;
        THROW 51000, 'Batch group ID must be a positive number', 1;
    End;

    ---------------------------------------------------
    -- Is batch group in table?
    ---------------------------------------------------

    If Not Exists (SELECT Batch_Group_ID FROM T_Requested_Run_Batch_Group WHERE Batch_Group_ID = @batchGroupID)
    Begin
        Set @message = 'Batch group does not exist: ' + Cast(@batchGroupID As Varchar(9))
        RAISERROR (@message, 10, 1)
        return 51150;
    End

    ---------------------------------------------------
    -- Delete batch group
    ---------------------------------------------------

    If @mode = 'Delete'
    Begin
        -- Assure that the batch group is not used by any batches
        If Exists (Select * From T_Requested_Run_Batches Where Batch_Group_ID = @batchGroupID)
        Begin
            set @message = 'Cannot delete batch group since used by one or more requested run batches: ' + Cast(@batchGroupID As Varchar(9))
            RAISERROR (@message, 10, 1)
            return 51151
        End
        Else
        Begin
            INSERT INTO T_Deleted_Requested_Run_Batch_Group (Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created)
            SELECT Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created
            FROM T_Requested_Run_Batch_Group
            WHERE Batch_Group_ID = @batchGroupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            DELETE FROM T_Requested_Run_Batch_Group
            WHERE Batch_Group_ID = @batchGroupID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                set @message = 'Failed trying to delete batch group'
                RAISERROR (@message, 10, 1)
                return 51152
            End
            return 0
        End
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
    return 51153

GO
GRANT VIEW DEFINITION ON [dbo].[do_requested_run_batch_group_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_requested_run_batch_group_operation] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_requested_run_batch_group_operation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_requested_run_batch_group_operation] TO [Limited_Table_Write] AS [dbo]
GO
