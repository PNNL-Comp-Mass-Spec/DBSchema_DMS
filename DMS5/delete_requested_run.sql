/****** Object:  StoredProcedure [dbo].[delete_requested_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_requested_run]
/****************************************************
**
**  Desc:
**      Remove a requested run (and all its dependencies)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/23/2006
**          10/29/2009 mem - Made @message an optional output parameter
**          02/26/2010 grk - delete factors
**          12/12/2011 mem - Added parameter @callingUser, which is passed to alter_event_log_entry_user
**          03/22/2016 mem - Added parameter @skipDatasetCheck
**          06/13/2017 mem - Fix typo
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/30/2023 mem - Append data to T_Deleted_Requested_Run and T_Deleted_Factor prior to deleting the requested run
**
*****************************************************/
(
    @requestID int = 0,                     -- Requested run ID to delete
    @skipDatasetCheck tinyint = 0,          -- Set to 1 to allow deleting a requested run even if it has an associated dataset
    @message varchar(512)='' output,
    @callingUser varchar(128) = ''
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Declare @batchID int
    Declare @eusPersonID int
    Declare @deletedBy Varchar(128)
    Declare @deletedRequestedRunEntryID Int

    Set @message = ''
    Set @skipDatasetCheck = Coalesce(@skipDatasetCheck, 0)
    
    Set @callingUser = Ltrim(Rtrim(Coalesce(@callingUser, '')))

    Set @deletedBy = CASE WHEN @callingUser = '' 
                          THEN SUSER_SNAME()
                          ELSE @callingUser 
                     END

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_requested_run', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the requested run ID
    ---------------------------------------------------
    --
    If @requestID = 0
    Begin
        Set @message = '@requestID is 0; nothing to do'
        goto Done
    End

    -- Verify that the request exists and check whether the request is in a batch
    --
    SELECT @batchID = RDS_BatchID
    FROM dbo.T_Requested_Run
    WHERE ID = @requestID;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'ID ' + Cast(@requestID as varchar(9)) + ' not found in T_Requested_Run; nothing to do'
        print @message
        goto Done
    End

    If @skipDatasetCheck = 0
    Begin
        Declare @DatasetID int = 0

        SELECT @DatasetID = DatasetID
        FROM T_Requested_Run
        WHERE ID = @requestID

        If Coalesce(@DatasetID, 0) > 0
        Begin
            Declare @Dataset varchar(128)

            SELECT @Dataset = Dataset_Num
            FROM T_Dataset
            WHERE Dataset_ID = @DatasetID

            Set @message = 'Cannot delete requested run ' + Cast(@requestID as varchar(9)) +
                           ' because it is associated with dataset ' + Coalesce(@Dataset, '??') +
                           ' (ID ' + Cast (@DatasetID as varchar(12)) + ')'

            Set @myError = 75
            Goto Done
        End
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------

    declare @transName varchar(32) = 'delete_requested_run'
    begin transaction @transName
    
    -- Look for an EUS user associated with the requested run
    -- If there is more than one user, only keep the first one (since, effective February 2020, requested runs are limited to a single EUS user)
    SELECT TOP 1 @eusPersonID = EUS_Person_ID
    FROM T_Requested_Run_EUS_Users 
    WHERE request_id = @requestID
    ORDER BY EUS_Person_ID Asc
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount < 1
        Set @eusPersonID = Null
  
    ---------------------------------------------------
    -- Add the requested run to T_Deleted_Requested_Run
    ---------------------------------------------------
    
    INSERT INTO T_Deleted_Requested_Run (
        Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group, 
        Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id, 
        Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id, 
        Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id, EUS_Person_Id, 
        Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment, 
        Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id, 
        Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By, Deleted_By
        )
    SELECT ID, RDS_Name, RDS_Requestor_PRN, RDS_comment, RDS_created, RDS_instrument_group, 
           RDS_type_ID, RDS_instrument_setting, RDS_special_instructions, RDS_Well_Plate_Num, RDS_Well_Num, RDS_priority, RDS_note, Exp_ID, 
           RDS_Run_Start, RDS_Run_Finish, RDS_Internal_Standard, RDS_WorkPackage, RDS_BatchID, 
           RDS_Blocking_Factor, RDS_Block, RDS_Run_Order, RDS_EUS_Proposal_ID, RDS_EUS_UsageType, @eusPersonID, 
           RDS_Cart_ID, RDS_Cart_Config_ID, RDS_Cart_Col, RDS_Sec_Sep, RDS_MRM_Attachment, 
           DatasetID, RDS_Origin, RDS_Status, RDS_NameCode, Vialing_Conc, Vialing_Vol, Location_ID, 
           Queue_State, Queue_Instrument_ID, Queue_Date, Entered, Updated, Updated_By, @deletedBy
    FROM T_Requested_Run
    WHERE ID = @requestID

    Set @deletedRequestedRunEntryID = SCOPE_IDENTITY()

    ---------------------------------------------------
    -- Add any factors to T_Deleted_Factor
    ---------------------------------------------------

    INSERT INTO T_Deleted_Factor (Factor_ID, Type, Target_ID, Name, Value, Last_Updated, Deleted_By, Deleted_Requested_Run_Entry_ID)
    SELECT FactorID, Type, TargetID, Name, Value, Last_Updated, @deletedBy, @deletedRequestedRunEntryID
    FROM T_Factor
    WHERE [Type] = 'Run_Request' AND
          TargetID = @requestID;

    ---------------------------------------------------
    -- Delete associated factors
    ---------------------------------------------------
    --
    DELETE FROM T_Factor
    WHERE [Type] = 'Run_Request' AND
          TargetID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to delete factors for request'
        goto Done
    end

    ---------------------------------------------------
    -- Delete EUS users associated with request
    ---------------------------------------------------
    --
    DELETE FROM dbo.T_Requested_Run_EUS_Users
    WHERE Request_ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to delete EUS users for request'
        goto Done
    end

    ---------------------------------------------------
    -- Delete requested run
    ---------------------------------------------------
    --
    DELETE FROM dbo.T_Requested_Run
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to delete request'
        goto Done
    end

    -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log

    If Len(@callingUser) > 0
    Begin
        Declare @stateID int
        Set @stateID = 0

        Exec alter_event_log_entry_user 11, @requestID, @stateID, @callingUser
    End

    commit transaction @transName

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If @batchID > 0
    Begin
        Exec update_cached_requested_run_batch_stats @batchID
    End

    ---------------------------------------------------
    -- Complete
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_requested_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_requested_run] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_requested_run] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_requested_run] TO [Limited_Table_Write] AS [dbo]
GO
