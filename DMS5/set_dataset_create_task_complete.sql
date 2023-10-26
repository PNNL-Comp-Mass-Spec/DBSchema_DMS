/****** Object:  StoredProcedure [dbo].[set_dataset_create_task_complete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_dataset_create_task_complete]
/****************************************************
**
**  Desc:
**      Update T_Dataset_Create_Queue after completing a dataset creation task
**
**  Arguments:
**    @entryID                  Entry_ID to update
**    @completionCode           Completion code; 0 means success; non-zero means failure
**    @completionMessage        Error message to store in T_Dataset_Create_Queue when @completionCode is non-zero
**    @message                  Output message
**
**  Return values:
**      0 for success, non-zero if an error
**
**  Auth:   mem
**          10/25/2023 mem - Initial version
**
*****************************************************/
(
    @entryID int,
    @completionCode int,
    @completionMessage varchar(2048),
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0

    Exec @authorized = verify_sp_authorized 'set_dataset_create_task_complete', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @entryID            = Coalesce(@entryID, 0);
    Set @completionCode     = Coalesce(@completionCode, 0);
    Set @completionMessage  = Coalesce(@completionMessage, '');

    ---------------------------------------------------
    -- Get current state of this dataset create task
    ---------------------------------------------------
    --
    Declare @stateID tinyint = 0
    Declare @datasetName varchar(128)
    
    SELECT @stateID = State_ID,
           @datasetName = Dataset
    FROM T_Dataset_Create_Queue
    WHERE Entry_ID = @entryID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error getting row from T_Dataset_Create_Queue'
        Return @myError
    End

    If @myRowCount = 0 Or @stateID <> 2
    Begin
        Set @message = 'Entry_ID ' + Cast(@entryID AS varchar(12))

        If @myRowCount = 0
        Begin
            Set @message = @message + ' was not found in T_Dataset_Create_Queue'
            Set @myError = 67
        End
        Else
        Begin
            Set @message = @message + ' is not in correct state to be completed; ' +
                           'expecting State=2 in T_Dataset_Create_Queue but actually ' + Cast(@stateID as varchar(12)) +
                           ' (' + @datasetName + ')'
            Set @myError = 68
        End

        Return @myError
    End

    ---------------------------------------------------
    -- Determine completion state
    ---------------------------------------------------

    If @completionCode = 0
        Set @stateID = 3
    Else
        Set @stateID = 4

    ---------------------------------------------------
    -- Start a new transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'SetDatasetCreationTaskComplete'
    Begin transaction @transName

    ---------------------------------------------------
    -- Update the state, finish time, and completion code
    ---------------------------------------------------
    --
    UPDATE T_Dataset_Create_Queue
    SET State_ID           = @stateID,
        Finish             = GetDate(),
        Completion_Code    = @completionCode,
        Completion_Message = @completionMessage
    WHERE Entry_ID = @entryID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error updating T_Dataset_Create_Queue for Entry_ID ' + Cast(@entryID As varchar(12)) + '; @myError = ' + Cast(@myError As varchar(12))
        Return @myError
    End

    -- Update was successful
    commit transaction @transName

    ---------------------------------------------------
    -- Make an entry in t_log_entries if the completion code is non-zero
    ---------------------------------------------------

    If @completionCode <> 0
    Begin
        Declare @logMessage varchar(512)

        Set @logMessage = 'Dataset creation task ' + Cast(@entryID as varchar(12)) +
                          ' reported completion code ' + Cast(@completionCode as varchar(12)) +
                          ': ' + @completionMessage +
                          ' (dataset ' + @datasetName + ')';

        EXEC post_log_entry 'Error', @logMessage, 'set_dataset_create_task_complete';
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[set_dataset_create_task_complete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_dataset_create_task_complete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_dataset_create_task_complete] TO [svc-dms] AS [dbo]
GO
