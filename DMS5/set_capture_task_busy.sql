/****** Object:  StoredProcedure [dbo].[set_capture_task_busy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_capture_task_busy]
/****************************************************
**
**  Desc:
**  Sets appropriate dataset state to busy
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   12/15/2009
**          01/14/2010 grk - removed path ID fields
**          09/02/2011 mem - Now calling post_usage_log_entry
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @machineName varchar(64),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    UPDATE T_Dataset
    SET
        DS_state_ID = 2,
        DS_PrepServerName = @machineName
    WHERE
        Dataset_Num = @datasetName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Update operation failed'
    end

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Dataset: ' + @datasetName
    Exec post_usage_log_entry 'set_capture_task_busy', @UsageMessage

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_capture_task_busy] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[set_capture_task_busy] TO [Limited_Table_Write] AS [dbo]
GO
