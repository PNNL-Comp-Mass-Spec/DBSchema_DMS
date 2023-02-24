/****** Object:  StoredProcedure [dbo].[SetArchiveUpdateRequired] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SetArchiveUpdateRequired]
/****************************************************
**
**  Desc:
**      Sets archive status of dataset to update required
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   12/3/2002
**          03/06/2007 grk - add changes for deep purge (ticket #403)
**          03/07/2007 dac - fixed incorrect check for "in progress" update states (ticket #408)
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          07/09/2022 mem - Tabs to spaces
**          01/10/2023 mem - Rename view to V_Dataset_Archive_Ex and use new column name
**
*****************************************************/
(
    @datasetNum varchar(128),
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    set @message = ''

    Declare @datasetID int
    Declare @updateState int
    Declare @archiveState int

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------
    --
    set @datasetID = 0
    set @updateState = 0
    --
    SELECT @datasetID = Dataset_ID,
           @updateState = Update_State,
           @archiveState = Archive_State
    FROM V_Dataset_Archive_Ex
    WHERE Dataset = @datasetNum
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @myError = 51220
        set @message = 'Error trying to get dataset ID for dataset "' + @datasetNum + '"'
        goto done
    end

    ---------------------------------------------------
    -- Check dataset archive update state for "in progress"
    ---------------------------------------------------
    if not @updateState in (1, 2, 4, 5)
    begin
        set @myError = 51250
        set @message = 'Archive update state for dataset "' + @datasetNum + '" is not correct'
        goto done
    end

    ---------------------------------------------------
    -- If archive state is "purged", set it to "complete"
    -- to allow for re-purging
    ---------------------------------------------------
    if @archiveState = 4
    begin
        set @archiveState = 3
    end

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    UPDATE T_Dataset_Archive
    SET AS_update_state_ID = 2,  AS_state_ID = @archiveState
    WHERE     (AS_Dataset_ID = @datasetID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @message = 'Update operation failed'
        set @myError = 99
        goto done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Dataset: ' + @datasetNum
    Exec PostUsageLogEntry 'SetArchiveUpdateRequired', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateRequired] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetArchiveUpdateRequired] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateRequired] TO [Limited_Table_Write] AS [dbo]
GO
