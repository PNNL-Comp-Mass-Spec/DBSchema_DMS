/****** Object:  StoredProcedure [dbo].[ConsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ConsumeScheduledRun]
/****************************************************
**
**  Desc:
**  Associates given requested run with the given dataset
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/13/2003
**          01/05/2002 grk - Added stuff for Internal Standard and cart parameters
**          03/01/2004 grk - Added validation for experiments matching between request and dataset
**          10/12/2005 grk - Added stuff to copy new work package and proposal fields.
**          01/13/2006 grk - Handling for new blocking columns in request and history tables.
**          01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**          04/08/2008 grk - Added handling for separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          11/29/2011 mem - Now calling AddRequestedRunToExistingDataset if re-using an existing request
**          12/05/2011 mem - Updated call to AddRequestedRunToExistingDataset to include @DatasetNum
**                         - Now copying batch and blocking info from the existing request to the new auto-request created by AddRequestedRunToExistingDataset
**          12/12/2011 mem - Updated log message when re-using an existing request
**          12/14/2011 mem - Added parameter @callingUser, which is passed to AddRequestedRunToExistingDataset and AlterEventLogEntryUser
**          11/16/2016 mem - Call UpdateCachedRequestedRunEUSUsers to update T_Active_Requested_Run_Cached_EUS_Users
**          11/21/2016 mem - Add parameter @logDebugMessages
**          05/22/2017 mem - No longer abort the addition if a request already exists named AutoReq_DatasetName
**
*****************************************************/
(
    @datasetID int,
    @requestID int,
    @message varchar(255) output,
    @callingUser varchar(128) = '',
    @logDebugMessages tinyint = 0
)
AS
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @ExistingDatasetID int
    Declare @LogMessage varchar(512)

    Set @message = ''

    ---------------------------------------------------
    -- Validate that experiments match
    ---------------------------------------------------

    -- get experiment ID from dataset
    --
    Declare @experimentID int
    Set @experimentID = 0
    --
    SELECT   @experimentID = Exp_ID
    FROM T_Dataset
    WHERE Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to look up experiment for dataset'
        RAISERROR (@message, 10, 1)
        return 51085
    End

    -- get experiment ID from scheduled run
    --
    Declare @reqExperimentID int
    Set @reqExperimentID = 0
    --
    SELECT @reqExperimentID = Exp_ID
    FROM T_Requested_Run
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to look up experiment for request'
        RAISERROR (@message, 10, 1)
        return 51086
    End

    -- validate that experiments match
    --
    If @experimentID <> @reqExperimentID
    Begin
        Set @message = 'Experiment in dataset does not match with one in scheduled run'
        RAISERROR (@message, 10, 1)
        return 51072
    End

    ---------------------------------------------------
    -- start transaction
    ---------------------------------------------------

    Declare @transName varchar(128)
    Set @transName = 'ConsumeScheduledRun_' + convert(varchar(12), @datasetID) + '_' + convert(varchar(12), @requestID)

    If @logDebugMessages = 1
    Begin
        Set @LogMessage = 'Start transaction ' + @transName
        exec PostLogEntry 'Debug', @LogMessage, 'ConsumeScheduledRun'
    End

    Begin transaction @transName

    -- If request already has a dataset associated with it, then we need to create a new auto-request for that dataset
    Set @ExistingDatasetID = 0
    --
    SELECT @ExistingDatasetID = DatasetID
    FROM T_Requested_Run
    WHERE ID = @requestID AND Not DatasetID Is Null

    If @ExistingDatasetID <> 0 And @ExistingDatasetID <> @datasetID
    Begin -- <a>
        ---------------------------------------------------
        -- Create new auto-request, but only if the dataset doesn't already have one
        ---------------------------------------------------

        Declare @ExistingDatasetName varchar(255) = ''

        SELECT @ExistingDatasetName = Dataset_Num
        FROM T_Dataset
        WHERE Dataset_ID = @ExistingDatasetID

        -- Change DatasetID to Null for this request before calling AddRequestedRunToExistingDataset
        UPDATE T_Requested_Run
        SET DatasetID = Null
        WHERE ID = @requestID

        exec AddRequestedRunToExistingDataset @datasetID=@ExistingDatasetID, @datasetNum='', @templateRequestID=@requestID, @mode='add', @message=@message output, @callingUser=@callingUser

        -- Lookup the request ID created for @ExistingDatasetName
        Declare @NewAutoRequestID INT = 0

        SELECT @NewAutoRequestID = RR.ID
        FROM   T_Requested_Run AS RR
        WHERE  RR.DatasetID = @ExistingDatasetID

        If @NewAutoRequestID <> 0
        Begin -- <b1>

            Set @LogMessage = 'Added new automatic requested run since re-using request ' + Convert(varchar(12), @requestID) + '; dataset "' + @ExistingDatasetName + '" is now associated with request ' + Convert(varchar(12), @NewAutoRequestID)
            exec PostLogEntry 'Warning', @LogMessage, 'ConsumeScheduledRun'

            -- Copy batch and blocking information from the existing request to the new request
            UPDATE Target
            SET RDS_BatchID = Source.RDS_BatchID,
                RDS_Blocking_Factor = Source.RDS_Blocking_Factor,
                RDS_Block = Source.RDS_Block,
                RDS_Run_Order = Source.RDS_Run_Order
            FROM T_Requested_Run Target
                    CROSS JOIN ( SELECT RDS_BatchID,
                                        RDS_Blocking_Factor,
                                        RDS_Block,
                                        RDS_Run_Order
                                FROM T_Requested_Run
                                WHERE ID = @requestID
                            ) Source
            WHERE Target.ID = @NewAutoRequestID

        End -- </b1>
        Else
        Begin -- <b2>

            Set @LogMessage = 'Tried to add a new automatic requested run for dataset "' + @ExistingDatasetName + '" since re-using request ' + Convert(varchar(12), @requestID) + '; however, AddRequestedRunToExistingDataset was unable to auto-create a new Requested Run'
            exec PostLogEntry 'Error', @LogMessage, 'ConsumeScheduledRun'

        End -- </b2>

    End -- </a>


    ---------------------------------------------------
    -- Change the status of the Requested Run to Completed
    ---------------------------------------------------

    Declare @status varchar(24) = 'Completed'

    UPDATE T_Requested_Run
    SET DatasetID = @datasetID,
        RDS_Status = @status
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Failed to update dataset field in request'
        Rollback Transaction @transName
        return 51009
    End

    -- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
    If Len(@callingUser) > 0
    Begin
        Declare @StatusID int = 0

        SELECT @StatusID = State_ID
        FROM T_Requested_Run_State_Name
        WHERE (State_Name = @status)

        Exec AlterEventLogEntryUser 11, @requestID, @StatusID, @callingUser
    End

    ---------------------------------------------------
    -- Finalize the changes
    ---------------------------------------------------
    --
    Commit Transaction @transName

    If @logDebugMessages = 1
    Begin
        Set @LogMessage = 'Call UpdateCachedRequestedRunEUSUsers for ' + Cast(@requestID as varchar(12))
        exec PostLogEntry 'Debug', @LogMessage, 'ConsumeScheduledRun'
    End

    ---------------------------------------------------
    -- Make sure that T_Active_Requested_Run_Cached_EUS_Users is up-to-date
    -- This procedure will delete the cached EUS user list from T_Active_Requested_Run_Cached_EUS_Users for this request ID
    ---------------------------------------------------
    --
    exec UpdateCachedRequestedRunEUSUsers @requestID

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ConsumeScheduledRun] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ConsumeScheduledRun] TO [Limited_Table_Write] AS [dbo]
GO
