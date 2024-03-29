/****** Object:  StoredProcedure [dbo].[set_archive_task_complete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_archive_task_complete]
/****************************************************
**
**  Desc:
**      Sets status of task to successful completion or to failed
**      (according to value of input argument)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**    @datasetName               dataset for which archive task is being completed
**    @completionCode            0->success, 1->failure, anything else ->no intermediate files
**
**  Auth:   grk
**  Date:   09/26/2002
**          06/21/2005 grk - added handling for "requires_preparation"
**          11/27/2007 dac - removed @processorname param, which is no longer required
**          03/23/2009 mem - Now updating AS_Last_Successful_Archive when the archive state is 3=Complete (Ticket #726)
**          12/17/2009 grk - added special success code '100' for use by capture broker
**          09/02/2011 mem - Now calling post_usage_log_entry
**          07/09/2022 mem - Tabs to spaces
**          01/10/2023 mem - Rename view to V_Dataset_Archive_Ex and use new column name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @completionCode int = 0,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    set @message = ''

    Declare @datasetID int
    Declare @archiveState int
    Declare @doPrep tinyint

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------
    --
    set @datasetID = 0
    set @archiveState = 0
    --
    SELECT @datasetID = Dataset_ID,
           @archiveState = Archive_State,
           @doPrep = Requires_Prep
    FROM V_Dataset_Archive_Ex
    WHERE Dataset = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @myError = 51220
        set @message = 'Error trying to get dataset ID for dataset "' + @datasetName + '"'
        goto done
    end

    ---------------------------------------------------
    -- Check dataset archive state for "in progress"
    ---------------------------------------------------
    if @archiveState <> 2
    begin
        set @myError = 51250
        set @message = 'Archive state for dataset "' + @datasetName + '" is not correct'
        goto done
    end

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    if @completionCode = 0 OR @completionCode = 100 -- task completed successfully
    begin
        -- decide what state is next
        --
        DECLARE @tmpState INT
        IF @completionCode = 100
        SET @tmpState = 3
        ELSE
        IF @doPrep = 0
            SET @tmpState = 3
        ELSE
            SET @tmpState = 11
        --
        -- update the state
        --
        UPDATE T_Dataset_Archive
        SET
            AS_state_ID = @tmpState,
            AS_update_state_ID = 4,
            AS_last_update = GETDATE(),
            AS_last_verify = GETDATE(),
            AS_Last_Successful_Archive =
                    CASE WHEN @tmpState = 3
                    THEN GETDATE()
                    ELSE AS_Last_Successful_Archive
                    END
        WHERE (AS_Dataset_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end
    else   -- task completed unsuccessfully
    begin
        UPDATE T_Dataset_Archive
        SET    AS_state_ID = 6
        WHERE  (AS_Dataset_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    end
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
    Set @UsageMessage = 'Dataset: ' + @datasetName
    Exec post_usage_log_entry 'set_archive_task_complete', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_archive_task_complete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_archive_task_complete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[set_archive_task_complete] TO [Limited_Table_Write] AS [dbo]
GO
