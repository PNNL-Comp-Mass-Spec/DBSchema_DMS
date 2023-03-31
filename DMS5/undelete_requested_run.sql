/****** Object:  StoredProcedure [dbo].[undelete_requested_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[undelete_requested_run]
/****************************************************
**
**  Desc:
**      Restore a deleted requested run
**
**  Auth:   mem
**  Date:   03/30/2023 mem - Initial version
**
*****************************************************/
(
    @requestID int = 0,                     -- Requested run ID to restore
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @entryID int
    Declare @batchID int
    Declare @eusPersonID int

    Set @message = ''
    Set @infoOnly = Coalesce(@infoOnly, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'undelete_requested_run', @raiseError = 1

    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the requested run ID
    ---------------------------------------------------
    --
    If Coalesce(@requestID, 0) = 0
    Begin
        Set @message = '@requestID is 0; nothing to do'
        goto Done
    End

    -- Verify that the deleted requested run exists, and lookup the batch ID and EUS person ID
    --
    SELECT Top 1 @entryID = Entry_ID,
                 @batchID = Batch_Id,
                 @eusPersonID = EUS_Person_Id
    FROM dbo.T_Deleted_Requested_Run
    WHERE Request_ID = @requestID
    ORDER BY Entry_Id DESC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Requested Run ID ' + Cast(@requestID as varchar(9)) + ' not found in T_Deleted_Requested_Run; unable to restore'
        print @message
        goto Done
    End

    ---------------------------------------------------
    -- Make sure the requested run does not already exist
    ---------------------------------------------------
    
    If Exists (SELECT ID FROM T_Requested_Run WHERE ID = @requestID)
    Begin
        Set @message = 'Requested Run ID ' + Cast(@requestID as varchar(9)) + ' already exists in T_Requested_Run; unable to undelete'
        print @message
        goto Done
    End

    If Exists (Select TargetID From T_Factor Where Type = 'Run_Request' And TargetID = @requestID)
    Begin
        Set @message = 'Requested Run ID ' + Cast(@requestID as varchar(9)) + ' not found in T_Requested_Run, but found in T_Factor; delete from T_Factor then call this procedure again'
        print @message
        goto Done
    End

    If Exists (Select Request_ID From T_Requested_Run_EUS_Users Where Request_ID = @requestID)
    Begin
        Set @message = 'Requested Run ID ' + Cast(@requestID as varchar(9)) + ' not found in T_Requested_Run, but found in T_Requested_Run_EUS_Users; delete from T_Requested_Run_EUS_Users then call this procedure again'
        print @message
        goto Done
    End

    If @infoOnly > 0
    Begin
        Set @message = 'Would restore requested run ID ' + Cast(@requestID as varchar(9)) + ' by copying Entry_ID ' + Cast(@entryID as varchar(9)) + ' from T_Deleted_Requested_Run to T_Requested_Run';
        print @message
        goto Done
    End

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------

    Declare @transName varchar(32) = 'undelete_requested_run'
    begin transaction @transName
   
    ---------------------------------------------------
    -- Add the requested run to T_Requested_Run
    ---------------------------------------------------
    
    Set IDENTITY_INSERT T_Requested_Run ON;

    INSERT INTO T_Requested_Run (
           ID, RDS_Name, RDS_Requestor_PRN, RDS_comment, RDS_created, RDS_instrument_group, 
           RDS_type_ID, RDS_instrument_setting, RDS_special_instructions, RDS_Well_Plate_Num, RDS_Well_Num, RDS_priority, RDS_note, Exp_ID, 
           RDS_Run_Start, RDS_Run_Finish, RDS_Internal_Standard, RDS_WorkPackage, RDS_BatchID, 
           RDS_Blocking_Factor, RDS_Block, RDS_Run_Order, RDS_EUS_Proposal_ID, RDS_EUS_UsageType,
           RDS_Cart_ID, RDS_Cart_Config_ID, RDS_Cart_Col, RDS_Sec_Sep, RDS_MRM_Attachment, 
           DatasetID, RDS_Origin, RDS_Status, RDS_NameCode, Vialing_Conc, Vialing_Vol, Location_ID, 
           Queue_State, Queue_Instrument_ID, Queue_Date, Entered, Updated, Updated_By
        )
    SELECT Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group, 
           Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id, 
           Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id, 
           Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id,
           Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment, 
           Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id, 
           Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By    
    FROM T_Deleted_Requested_Run
    WHERE Entry_ID = @entryID

    Set IDENTITY_INSERT T_Requested_Run OFF;
    
    If Coalesce(@eusPersonID, 0) > 0
    Begin
        Insert Into T_Requested_Run_EUS_Users (Request_id, EUS_Person_ID)
        Values (@requestID, @eusPersonID)
    End

    ---------------------------------------------------
    -- Add any factors to T_Factor
    ---------------------------------------------------

    Set IDENTITY_INSERT T_Factor ON;
    
    INSERT INTO T_Factor (FactorID, Type, TargetID, Name, Value, Last_Updated)
    SELECT Factor_ID, Type, Target_ID, Name, Value, Last_Updated
    FROM T_Deleted_Factor
    WHERE [Type] = 'Run_Request' AND
          Target_ID = @requestID And
          Deleted_Requested_Run_Entry_ID = @entryID;

    Set IDENTITY_INSERT T_Factor OFF;

    commit transaction @transName

    Set @message = 'Restored requested run ID ' + Cast(@requestID as varchar(9))
    print @message

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
