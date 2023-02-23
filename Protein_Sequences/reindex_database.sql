/****** Object:  StoredProcedure [dbo].[reindex_database] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reindex_database]
/****************************************************
**
**  Desc:
**      Reindexes the key tables in the database
**      Once complete, updates reindex_databaseNow to 0 in T_Process_Step_Control
**
**  Return values: 0:  success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/11/2007
**          10/30/2007 mem - Now calling verify_update_enabled
**          10/09/2008 mem - Added T_Score_Inspect
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowcount int
    set @myRowcount = 0
    set @myError = 0

    Declare @TableCount int
    Set @TableCount = 0

    declare @UpdateEnabled tinyint

    Set @message = ''

    -----------------------------------------------------------
    -- Reindex the data tables
    -----------------------------------------------------------
    DBCC DBREINDEX (T_Archived_Output_Files, '', 90)
    Set @TableCount = @TableCount + 1

    -- Validate that updating is enabled, abort if not enabled
    exec verify_update_enabled @CallingFunctionDescription = 'reindex_database', @AllowPausing = 1, @UpdateEnabled = @UpdateEnabled output, @message = @message output
    If @UpdateEnabled = 0
        Goto Done

    DBCC DBREINDEX (T_Protein_Names, '', 90)
    Set @TableCount = @TableCount + 1

    -- Validate that updating is enabled, abort if not enabled
    exec verify_update_enabled @CallingFunctionDescription = 'reindex_database', @AllowPausing = 1, @UpdateEnabled = @UpdateEnabled output, @message = @message output
    If @UpdateEnabled = 0
        Goto Done

    DBCC DBREINDEX (T_Proteins, '', 90)
    Set @TableCount = @TableCount + 1

    -- Validate that updating is enabled, abort if not enabled
    exec verify_update_enabled @CallingFunctionDescription = 'reindex_database', @AllowPausing = 1, @UpdateEnabled = @UpdateEnabled output, @message = @message output
    If @UpdateEnabled = 0
        Goto Done

    DBCC DBREINDEX (T_Protein_Headers, '', 90)
    Set @TableCount = @TableCount + 1

    -- Validate that updating is enabled, abort if not enabled
    exec verify_update_enabled @CallingFunctionDescription = 'reindex_database', @AllowPausing = 1, @UpdateEnabled = @UpdateEnabled output, @message = @message output
    If @UpdateEnabled = 0
        Goto Done

    DBCC DBREINDEX (T_Protein_Collection_Members, '', 90)
    Set @TableCount = @TableCount + 1

    -----------------------------------------------------------
    -- Log the reindex
    -----------------------------------------------------------

    Set @message = 'Reindexed ' + Convert(varchar(12), @TableCount) + ' tables'
    Exec post_log_entry 'Normal', @message, 'reindex_database'

    -----------------------------------------------------------
    -- Update T_Process_Step_Control
    -----------------------------------------------------------

    -- Set 'reindex_databaseNow' to 0
    --
    UPDATE T_Process_Step_Control
    SET Enabled = 0
    WHERE (Processing_Step_Name = 'reindex_databaseNow')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Entry "reindex_databaseNow" not found in T_Process_Step_Control; adding it'
        Exec post_log_entry 'Error', @message, 'reindex_database'

        INSERT INTO T_Process_Step_Control (Processing_Step_Name, Enabled)
        VALUES ('reindex_databaseNow', 0)
    End

    -- Set 'InitialDBReindexComplete' to 1
    --
    UPDATE T_Process_Step_Control
    SET Enabled = 1
    WHERE (Processing_Step_Name = 'InitialDBReindexComplete')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Entry "InitialDBReindexComplete" not found in T_Process_Step_Control; adding it'
        Exec post_log_entry 'Error', @message, 'reindex_database'

        INSERT INTO T_Process_Step_Control (Processing_Step_Name, Enabled)
        VALUES ('InitialDBReindexComplete', 1)
    End


Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [MTS_DB_Dev] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [MTS_DB_Lite] AS [dbo]
GO
