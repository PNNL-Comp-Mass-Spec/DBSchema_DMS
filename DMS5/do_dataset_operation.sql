/****** Object:  StoredProcedure [dbo].[do_dataset_operation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[do_dataset_operation]
/****************************************************
**
**  Desc:   Perform dataset operation defined by 'mode'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   04/08/2002
**          08/07/2003 grk - allowed reset from "Not Ready" state
**          05/05/2005 grk - removed default value from mode
**          03/24/2006 grk - added "restore" mode
**          09/15/2006 grk - repair "restore" mode
**          03/27/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644)
**          07/15/2008 jds - Added "delete_all" mode (Ticket #644) - deletes a dataset without any restrictions
**          08/19/2010 grk - try-catch for error handling
**          05/25/2011 mem - Fixed bug that reported "mode was unrecognized" for valid modes
**                         - Removed 'restore' mode
**          01/12/2012 mem - Now preventing deletion if @mode is 'delete' and the dataset exists in S_V_Capture_Tasks_Active_Or_Complete
**          11/14/2013 mem - Now preventing reset if the first step of dataset capture succeeded
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/10/2017 mem - Add @mode 'createjobs' which adds the dataset to T_Predefined_Analysis_Scheduling_Queue so that default jobs will be created
**                           (duplicate jobs are not created)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/04/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/03/2017 mem - Allow resetting a dataset if DatasetIntegrity failed
**          08/08/2017 mem - Use function remove_capture_errors_from_string to remove common dataset capture errors when resetting a dataset
**          09/07/2018 mem - Remove mode 'delete_all'; if you need to delete a dataset, manually call stored procedure delete_dataset
**                         - Rename @datasetNum to @datasetNameOrID
**          09/27/2018 mem - Use named parameter names when calling delete_dataset
**          11/16/2018 mem - Pass @infoOnly to delete_dataset
**          02/01/2023 mem - Use new synonym names
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new synonym names
**
*****************************************************/
(
    @datasetNameOrID varchar(128),          -- Dataset name or dataset ID
    @mode varchar(12),                      -- 'delete', 'reset', 'createjobs'; legacy version supported 'burn' and 'delete_all'
    @message varchar(512) output,
    @callingUser varchar (128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(256)
    Declare @logMsg varchar(256)

    Declare @datasetID int = 0

    Declare @currentState int
    Declare @NewState int

    Declare @currentComment varchar(512)

    Declare @result int
    Declare @ValidMode tinyint = 0
    Declare @logErrors tinyint = 0

    Begin TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'do_dataset_operation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Get datasetID and current state
    ---------------------------------------------------

    Declare @candidateDatasetID int = Try_Cast(@datasetNameOrID As int)
    Declare @datasetName varchar(128) = ''

    If IsNull(@candidateDatasetID, 0) > 0
    Begin
        SELECT
            @currentState = DS_state_ID,
            @currentComment = DS_Comment,
            @datasetID = Dataset_ID,
            @datasetName = Dataset_Num
        FROM T_Dataset
        WHERE (Dataset_ID = @candidateDatasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        SELECT
            @currentState = DS_state_ID,
            @currentComment = DS_Comment,
            @datasetID = Dataset_ID,
            @datasetName = Dataset_Num
        FROM T_Dataset
        WHERE (Dataset_Num = @datasetNameOrID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    --
    If @myError <> 0
    Begin
        set @msg = 'Could not get ID or state for dataset "' + @datasetNameOrID + '"'
        RAISERROR (@msg, 11, 1)
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Schedule the dataset for predefined job processing
    ---------------------------------------------------
    --
    If @mode = 'createjobs'
    Begin
        If IsNull(@callingUser, '') = ''
            Set @callingUser = SUSER_SNAME()

        If Exists (SELECT * FROM T_Predefined_Analysis_Scheduling_Queue WHERE Dataset_ID = @datasetID AND State = 'New')
        Begin
            Declare @enteredMax datetime

            SELECT @enteredMax = Max(Entered)
            FROM T_Predefined_Analysis_Scheduling_Queue
            WHERE Dataset_ID = @datasetID AND State = 'New'

            Declare @elapsedHours float = DateDiff(minute, IsNull(@enteredMax, GetDate()), GetDate()) / 60.0

            Set @logErrors = 0

            If @elapsedHours >= 0.5
            Begin
                -- Round @elapsedHours to one digit, then convert to a string
                Declare @elapsedHoursText varchar(9) = Cast(Cast(Round(@elapsedHours, 1) AS Numeric(12,1)) AS varchar(9))
                RAISERROR ('Default job creation for dataset ID %d has been waiting for %s hours; please contact a DMS administrator to diagnose the delay', 11, 2, @datasetID, @elapsedHoursText)
            End
            Else
            Begin
                RAISERROR ('Dataset ID %d is already scheduled to have default jobs created; please wait at least 5 minutes', 11, 2, @datasetID)
            End

        End

        INSERT INTO T_Predefined_Analysis_Scheduling_Queue (Dataset_ID, CallingUser)
        VALUES (@datasetID, @callingUser)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            RAISERROR ('Error adding "%s" to T_Predefined_Analysis_Scheduling_Queue, error code %d', 11, 2, @datasetName, @myError)
        End

        set @ValidMode = 1

    End -- </createjobs>

    ---------------------------------------------------
    -- Delete dataset if it is in "new" state only
    ---------------------------------------------------
    --
    If @mode = 'delete'
    Begin

        ---------------------------------------------------
        -- verify that dataset is still in 'new' state
        ---------------------------------------------------

        If @currentState <> 1
        Begin
            Set @logErrors = 0
            set @msg = 'Dataset "' + @datasetName + '" must be in "new" state to be deleted by user'
            RAISERROR (@msg, 11, 3)
        End

        ---------------------------------------------------
        -- Verify that the dataset does not have an active or completed capture job
        ---------------------------------------------------

        If Exists (SELECT * FROM S_V_Capture_Tasks_Active_Or_Complete WHERE Dataset_ID = @datasetID And State <= 2)
        Begin
            set @msg = 'Dataset "' + @datasetName + '" is being processed by the DMS_Capture database; unable to delete'
            RAISERROR (@msg, 11, 3)
        End

        If Exists (SELECT * FROM S_V_Capture_Tasks_Active_Or_Complete WHERE Dataset_ID = @datasetID And State > 2)
        Begin
            set @msg = 'Dataset "' + @datasetName + '" has been processed by the DMS_Capture database; unable to delete'
            RAISERROR (@msg, 11, 3)
        End


        ---------------------------------------------------
        -- Delete the dataset
        ---------------------------------------------------

        execute @result = delete_dataset @datasetName, @infoOnly=0, @message = @message output, @callingUser = @callingUser
        --
        If @result <> 0
        Begin
            RAISERROR ('Could not delete dataset "%s"', 11, 4, @datasetName)
        End

        set @ValidMode = 1

    End -- </delete>

    ---------------------------------------------------
    -- Reset state of failed dataset to 'new'
    -- This is used by the "Retry Capture" button on the dataset detail report page
    ---------------------------------------------------
    --
    If @mode = 'reset'
    Begin

        -- If dataset not in failed state, can't reset it
        --
        If @currentState not in (5, 9) -- "Failed" or "Not ready"
        Begin
            Set @logErrors = 0
            set @msg = 'Dataset "' + @datasetName + '" cannot be reset if capture not in failed or in not ready state ' + cast(@currentState as varchar(12))
            RAISERROR (@msg, 11, 5)
        End

        -- Do not allow a reset if the dataset succeeded the first step of capture
        If Exists (SELECT * FROM S_V_Capture_Task_Steps WHERE Dataset_ID = @datasetID AND Tool = 'DatasetCapture' AND State IN (1,2,4,5))
        Begin
            Declare @allowReset tinyint = 0

            If Exists (SELECT * FROM S_V_Capture_Task_Steps WHERE Dataset_ID = @datasetID AND Tool = 'DatasetIntegrity' AND State = 6) AND
               Exists (SELECT * FROM S_V_Capture_Task_Steps WHERE Dataset_ID = @datasetID AND Tool = 'DatasetCapture' AND State = 5)
            Begin
                -- Do allow a reset if the DatasetIntegrity step failed and if we haven't already retried capture of this dataset once
                set @msg = 'Retrying capture of dataset ' + @datasetName + ' at user request (dataset was captured, but DatasetIntegrity failed)'
                If Exists (SELECT * FROM T_Log_Entries WHERE message LIKE @msg + '%')
                Begin
                    Set @msg = 'Dataset "' + @datasetName + '" cannot be reset because it has already been reset once'

                    If @callingUser = ''
                        Set @logMsg = @msg + '; user ' + SUSER_SNAME()
                    Else
                        Set @logMsg = @msg + '; user ' + @callingUser

                    Exec post_log_entry 'Error', @logMsg, 'do_dataset_operation'

                    Set @msg = @msg + '; please contact a system administrator for further assistance'
                End
                Else
                Begin
                    Set @allowReset=1
                    If @callingUser = ''
                        Set @msg = @msg + '; user ' + SUSER_SNAME()
                    Else
                        Set @msg = @msg + '; user ' + @callingUser

                    Exec post_log_entry 'Warning', @msg, 'do_dataset_operation'
                End

            End
            Else
            Begin
                Set @msg = 'Dataset "' + @datasetName + '" cannot be reset because it has already been successfully captured; please contact a system administrator for further assistance'
            End

            If @allowReset = 0
            Begin
                Set @logErrors = 0
                RAISERROR (@msg, 11, 5)
            End
        End

        -- Update state of dataset to new
        --
        Set @NewState = 1         -- "new' state

        UPDATE T_Dataset
        SET DS_state_ID = @NewState,
            DS_Comment = dbo.remove_capture_errors_from_string(DS_Comment)
        WHERE Dataset_ID = @datasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            set @msg = 'Reset was unsuccessful for dataset "' + @datasetName + '"'
            RAISERROR (@msg, 11, 6)
        End

        -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
            Exec alter_event_log_entry_user 4, @datasetID, @NewState, @callingUser

        set @ValidMode = 1

    End -- </reset>


    If @ValidMode = 0
    Begin
        ---------------------------------------------------
        -- Mode was unrecognized
        ---------------------------------------------------

        set @msg = 'Mode "' + @mode +  '" was unrecognized'
        RAISERROR (@msg, 11, 10)
    End

    END TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Dataset ' + @datasetNameOrID
            Exec post_log_entry 'Error', @logMessage, 'do_dataset_operation'
        End
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[do_dataset_operation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_dataset_operation] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[do_dataset_operation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[do_dataset_operation] TO [Limited_Table_Write] AS [dbo]
GO
