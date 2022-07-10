/****** Object:  StoredProcedure [dbo].[SetArchiveUpdateTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SetArchiveUpdateTaskComplete]
/****************************************************
**
**  Desc:
**      Sets status of task to successful completion or to failed 
**      (according to value of input argument)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**    @datasetNum                dataset for which archive task is being completed
**    @completionCode            0->success, 1->failure, anything else ->no intermediate files
**
**  Auth:   grk
**  Date:   12/03/2002
**          12/06/2002 dac - Corrected state values used in update state test, update complete output
**          11/30/2007 dac - Removed unused processor name parameter
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/16/2014 mem - Now changing archive state to 3 if it is 14
**          07/09/2022 mem - Tabs to spaces
**
*****************************************************/
(
    @datasetNum varchar(128),
    @completionCode int = 0,
    @message varchar(512) output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    set @message = ''

    Declare @datasetID int
    Declare @updateState int

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------
    --
    set @datasetID = 0
    set @updateState = 0
    --
    SELECT     
        @datasetID = Dataset_ID, 
        @updateState = Update_State
    FROM V_DatasetArchive_Ex
    WHERE Dataset_Number = @datasetNum
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
    -- Check dataset archive state for "in progress"
    ---------------------------------------------------
    if @updateState <> 3
    begin
        set @myError = 51250
        set @message = 'Archive update state for dataset "' + @datasetNum + '" is not correct'
        goto done
    end

    Set @completionCode = IsNull(@completionCode, 0)
    
    ---------------------------------------------------
    -- Update dataset archive state 
    ---------------------------------------------------
    
    If @completionCode = 0
    Begin
        -- Success
        UPDATE T_Dataset_Archive
        SET AS_update_state_ID = 4,
            AS_state_ID = CASE
                              WHEN AS_state_ID = 14 THEN 3
                              ELSE AS_state_ID
                          END,
            AS_last_update = GETDATE()
        WHERE (AS_Dataset_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        -- Error
        UPDATE T_Dataset_Archive
        SET AS_update_state_ID = 5,
            AS_state_ID = CASE
                              WHEN AS_state_ID = 14 THEN 3
                              ELSE AS_state_ID
                          END
        WHERE(AS_Dataset_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
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
    Exec PostUsageLogEntry 'SetArchiveUpdateTaskComplete', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetArchiveUpdateTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetArchiveUpdateTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
