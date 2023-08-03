/****** Object:  StoredProcedure [dbo].[update_dataset_instrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dataset_instrument]
/****************************************************
**
**  Desc:   Changes the instrument name of a dataset
**          Typically used for datasets that are new and failed capture
**          due to the instrument name being wrong (e.g. 15T_FTICR instead of 15T_FTICR_Imaging)
**
**          However, set @updateCaptured to 1 to also allow
**          changing the instrument of a dataset that was already successfully captured
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/30/2019 mem - Initial Version
**          01/05/2023 mem - Use new column names in V_Storage_List_Report
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new synonym names and T_Task tables
**          04/01/2023 mem - Use new DMS_Capture procedures and function names
**          08/02/2023 mem - Add call to update_cached_dataset_instruments
**
*****************************************************/
(
    @datasetName Varchar(128),
    @newInstrument Varchar(64),
    @infoOnly tinyint = 1,
    @updateCaptured tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Declare @errMsg varchar(255)

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    Set @datasetName = IsNull(@datasetName, '')
    Set @newInstrument = IsNull(@newInstrument, '')
    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @updateCaptured = IsNull(@updateCaptured, 0)
    Set @message = ''

    ----------------------------------------------------------
    -- Lookup the dataset id and dataset state
    ----------------------------------------------------------

    Declare @datasetId int = 0
    Declare @state int = 0
    Declare @captureJob Int = 0
    Declare @stepState Int = 0
    Declare @datasetCreated DateTime
    Declare @instrumentIdOld Int
    Declare @instrumentIdNew Int
    Declare @storagePathIdOld int
    Declare @storagePathIdNew Int
    Declare @storagePathOld Varchar(128)
    Declare @storagePathNew Varchar(128)

    Declare @instrumentNameOld Varchar(128)
    Declare @instrumentNameNew Varchar(128)
    Declare @storageServerNew Varchar(64)
    Declare @instrumentClassNew Varchar(32)
    Declare @deleteCaptureJob Tinyint = 0

    SELECT @datasetId = Dataset_ID,
           @state = DS_state_ID,
           @datasetCreated = DS_created,
           @instrumentIdOld = DS_instrument_name_ID,
           @storagePathIdOld = DS_storage_path_ID
    FROM T_Dataset
    WHERE Dataset_Num = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or IsNull(@datasetId, 0) = 0
    Begin
        Set @message = 'Dataset not found: ' + @datasetName
        Set @myError = 50000
        Goto Done
    End

    If @updateCaptured = 0 And @state <> 5
    Begin
        Set @message = 'Dataset state is not "Capture failed"; not changing the instrument'
        Set @myError = 50001
        Goto Done
    End

    -- Find the capture job for this dataset
    SELECT @captureJob = Job,
           @stepState = State
    FROM S_V_Capture_Task_Steps
    WHERE Dataset_ID = @datasetId AND
            Tool = 'DatasetCapture'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or IsNull(@captureJob, 0) = 0
    Begin
        Set @message = 'Dataset capture job not found; not changing the instrument'
        Set @myError = 50002
        Goto Done
    End

    If @updateCaptured = 0 And IsNull(@stepState, 0) <> 6
    Begin
        Set @message = 'Dataset capture step state is not "Failed"; not changing the instrument'
        Set @myError = 50003
        Goto Done
    End

    If @stepState = 6
    Begin
        Set @deleteCaptureJob = 1
    End

    SELECT @instrumentNameOld = IN_name
    FROM T_Instrument_Name
    WHERE Instrument_ID = @instrumentIdOld
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    SELECT @instrumentIdNew = Instrument_ID,
           @instrumentNameNew = IN_name,
           @instrumentClassNew = IN_Class
    FROM T_Instrument_Name
    WHERE IN_name = @newInstrument
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or IsNull(@instrumentIdNew, 0) = 0
    Begin
        Set @message = 'New instrument not found: ' + @newInstrument
        Set @myError = 50000
        Goto Done
    End

    Exec @storagePathIdNew = get_instrument_storage_path_for_new_datasets @instrumentIdNew, @datasetCreated, @AutoSwitchActiveStorage=0, @infoOnly=0

    SELECT @storagePathNew = dbo.combine_paths(vol_client, storage_path)
    FROM V_Storage_List_Report
    WHERE ID = @storagePathIdNew

    If @infoOnly > 0
    Begin
        SELECT @storagePathOld = dbo.combine_paths(vol_client, storage_path)
        FROM V_Storage_List_Report
        WHERE ID = @storagePathIdOld

        SELECT @storagePathNew = dbo.combine_paths(vol_client, storage_path)
        FROM V_Storage_List_Report
        WHERE ID = @storagePathIdNew

        SELECT ID,
               Dataset,
               Experiment,
               State,
               Instrument AS Instrument_Old,
               @instrumentNameNew AS Instrument_New,
               @storagePathOld AS Storage_Path_Old,
               @storagePathNew AS Storage_Path_New,
               Created
        FROM V_Dataset_List_Report_2
        WHERE ID = @datasetId

        SELECT *
        FROM S_V_Capture_Task_Steps
        WHERE Job = @captureJob And
              Tool = 'DatasetCapture'

        Goto Done
    End

    SELECT @storageServerNew = SP_Machine_Name
    FROM T_Storage_Path
    WHERE SP_Path_ID = @storagePathIdNew
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myRowCount = 0
    Begin
        Set @message = 'Storage path ID ' + Cast(@storagePathIdNew As Varchar(12)) + ' not found in T_Storage_Path; aborting'
        If @myError = 0
        Begin
            Set @myError= 50010
        End
        Goto Done
    End

    Declare @instrumentUpdateTran Varchar(32) = 'Instrument update'
    Begin Tran @instrumentUpdateTran

    Update T_Dataset
    Set DS_instrument_name_ID = @instrumentIdNew,
        DS_storage_path_ID = @storagePathIdNew
    Where Dataset_ID = @datasetId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Rollback Tran @instrumentUpdateTran
        Set @message = 'Error updating DS_instrument_name_ID and DS_storage_path_ID in Dataset_ID; aborting'
        Goto Done
    End

    If @deleteCaptureJob = 0
    Begin

        Update DMS_Capture.dbo.T_Tasks
        Set Storage_Server = @storageServerNew,
            Instrument = @instrumentNameNew,
            Instrument_Class = @instrumentClassNew
        Where Job = @captureJob And Dataset_ID = @datasetId
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Rollback Tran @instrumentUpdateTran
            Set @message = 'Error updating job ' + Cast(@captureJob As Varchar(12)) + ' in DMS_Capture.dbo.T_Tasks; aborting'
            Goto Done
        End

        Exec DMS_Capture.dbo.update_parameters_for_task @captureJob
    End
    Else
    Begin
        Delete DMS_Capture.dbo.T_Tasks
        Where Job = @captureJob And Dataset_ID = @datasetId
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Rollback Tran @instrumentUpdateTran
            Set @message = 'Error deleting job ' + Cast(@captureJob As Varchar(12)) + ' in DMS_Capture.dbo.T_Tasks; aborting'
            Goto Done
        End

        Update T_Dataset
        Set DS_state_ID = 1
        Where Dataset_ID = @datasetId
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Rollback Tran @instrumentUpdateTran
            Set @message = 'Error updating DS_State_ID in T_Dataset; aborting'
            Goto Done
        End
    End

    Set @message = 'Changed instrument from ' + @instrumentNameOld + ' to ' + @instrumentNameNew + ' ' +
                   'for dataset ' + @datasetName + ', Dataset_ID ' + Cast(@datasetId As Varchar(12)) + '; ' +
                   'Storage path ID changed from ' +
                   Cast(@storagePathIdOld As Varchar(12)) + ' to ' + Cast(@storagePathIdNew As Varchar(12))

    Exec post_log_entry 'Normal', @message, 'update_dataset_instrument'

    Commit Tran @instrumentUpdateTran

    -- Update T_Cached_Dataset_Instruments
    Exec dbo.update_cached_dataset_instruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

Done:
    If Len(@message) > 0
    Begin
        If @myError <> 0
            Select @message As [Error Message]
        Else
            Print @message
    End

    Return @myError

GO
