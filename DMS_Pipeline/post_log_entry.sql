/****** Object:  StoredProcedure [dbo].[post_log_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[post_log_entry]
/****************************************************
**
**  Desc: Put new entry into the main log table
**
**  Return values: 0: success, otherwise, error code
*
**  Auth:   grk
**  Date:   10/31/2001
**          02/17/2005 mem - Added parameter @duplicateEntryHoldoffHours
**          05/31/2007 mem - Expanded the size of @type, @message, and @postedBy
**          02/27/2017 mem - Although @message is varchar(4096), the Message column in T_Log_Entries may be shorter (512 characters in DMS); disable ANSI Warnings before inserting into the table
**          01/28/2020 mem - Fix bug subtracting @duplicateEntryHoldoffHours from the current date/time
**          08/25/2022 mem - Use new column name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @type varchar(128),                         -- Typically Normal, Warning, Error, or Progress, but can be any text value
    @message varchar(4096),
    @postedBy varchar(128)= 'na',
    @duplicateEntryHoldoffHours int = 0         -- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
)
AS
    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @duplicateRowCount int = 0

    If IsNull(@duplicateEntryHoldoffHours, 0) > 0
    Begin
        SELECT @duplicateRowCount = COUNT(*)
        FROM T_Log_Entries
        WHERE Message = @message AND Type = @type AND Entered >= DateAdd(hour, -@duplicateEntryHoldoffHours, GetDate())
    End

    If @duplicateRowCount = 0
    Begin
        SET ANSI_WARNINGS OFF;

        INSERT INTO T_Log_Entries( posted_by,
                                   Entered,
                                   [Type],
                                   message )
        VALUES(@postedBy, GETDATE(), @type, @message);
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount;

        SET ANSI_WARNINGS ON;
        --
        if @myRowCount <> 1
        begin
            RAISERROR ('Update was unsuccessful for T_Log_Entries table', 10, 1)
            return 51191
        end
    End

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[post_log_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[post_log_entry] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[post_log_entry] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[post_log_entry] TO [svc-dms] AS [dbo]
GO
