/****** Object:  StoredProcedure [dbo].[AddArchiveDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddArchiveDataset]
/****************************************************
**
**  Desc:   Make new entry into the archive table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/26/2001
**          04/04/2006 grk - Added setting holdoff interval
**          01/14/2010 grk - Assign storage path on creation of archive entry
**          01/22/2010 grk - Existing entry in archive table prevents duplicate, but doesn't raise error
**          05/11/2011 mem - Now calling GetInstrumentArchivePathForNewDatasets to determine @archivePathID
**          05/12/2011 mem - Now passing @DatasetID and @AutoSwitchActiveArchive to GetInstrumentArchivePathForNewDatasets
**          06/01/2012 mem - Bumped up @holdOffHours to 2 weeks
**          06/12/2012 mem - Now looking up the Purge_Policy in T_Instrument_Name
**          08/10/2018 mem - Do not create an archive task for datasets with state 14
**          12/20/2021 bcg - Look up Purge_Priority and AS_purge_holdoff_date offset in T_Instrument_Name
**
*****************************************************/
(
    @datasetID int
)
AS
    Set Nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(512) = ''

    ---------------------------------------------------
    -- Don't allow duplicate dataset IDs in table
    ---------------------------------------------------
    --
    If Exists (SELECT * FROM T_Dataset_Archive WHERE (AS_Dataset_ID = @datasetID))
    Begin
        Set @message = 'Dataset ID ' + Cast(@datasetID As varchar(12)) + ' already in archive table'
        Print @message
        Return 0
    End

    ---------------------------------------------------
    -- Lookup the Instrument ID and dataset state
    ---------------------------------------------------

    Declare @instrumentID int = 0
    Declare @datasetStateId Int = 0
    --
    SELECT @instrumentID = DS_instrument_name_ID,
           @datasetStateId = DS_state_ID
    FROM T_Dataset
    WHERE Dataset_ID = @DatasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        set @message = 'Error looking up dataset info'
        RAISERROR (@message, 10, 1)
    End

    If @instrumentID = 0
    Begin
        set @message = 'Dataset ID ' + Cast(@datasetID As varchar(12)) + ' not found in T_Dataset'
        RAISERROR (@message, 10, 1)
        Return 51115
    End

    If @datasetStateId = 14
    Begin
        Set @message = 'Cannot create a dataset archive task for Dataset ID ' + Cast(@datasetID As varchar(12)) + '; ' +
                       'dataset state is 14 (Capture Failed, Duplicate Dataset Files)'
        Exec PostLogEntry 'Error', @message, 'AddArchiveDataset', 12
        RAISERROR (@message, 10, 1)
        Return 51110
    End

    ---------------------------------------------------
    -- Get the assigned archive path
    ---------------------------------------------------
    --
    Declare @archivePathID int = 0
    --
    exec @archivePathID = GetInstrumentArchivePathForNewDatasets @instrumentID, @DatasetID, @AutoSwitchActiveArchive=1, @infoOnly=0
    --
    If @archivePathID = 0
    Begin
        set @message = 'GetInstrumentArchivePathForNewDatasets returned zero for an archive path ID for dataset ' + Convert(varchar(12), @DatasetID)
        RAISERROR (@message, 10, 1)
        Return 51105
    End

    ---------------------------------------------------
    -- Lookup the purge policy for this instrument
    ---------------------------------------------------
    --
    Declare @purgePolicy tinyint = 0
    Declare @purgePriority tinyint = 0
    Declare @purgeHoldoffMonths tinyint = 0

    SELECT @purgePolicy = Default_Purge_Policy,
           @purgePriority = Default_Purge_Priority,
           @purgeHoldoffMonths = Storage_Purge_Holdoff_Months
    FROM T_Instrument_Name
    WHERE Instrument_ID = @instrumentID

    Set @purgePolicy = IsNull(@purgePolicy, 0)
    Set @purgePriority = IsNull(@purgePriority, 3)
    Set @purgeHoldoffMonths = IsNull(@purgeHoldoffMonths, 1)

    ---------------------------------------------------
    -- Make entry into archive table
    ---------------------------------------------------
    --
    INSERT INTO T_Dataset_Archive
        ( AS_Dataset_ID,
          AS_state_ID,
          AS_update_state_ID,
          AS_storage_path_ID,
          AS_datetime,
          AS_purge_holdoff_date,
          Purge_Policy,
          Purge_Priority
        )
    VALUES
        ( @datasetID,
          1,
          1,
          @archivePathID,
          GETDATE(),
          DATEADD(MONTH, @purgeHoldoffMonths, GETDATE()),
          @purgePolicy,
          @purgePriority
        )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount <> 1
    Begin
        RAISERROR ('Error adding new entry to T_Dataset_Archive', 10, 1)
        Return 51100
    End

    Return

GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [Limited_Table_Write] AS [dbo]
GO
