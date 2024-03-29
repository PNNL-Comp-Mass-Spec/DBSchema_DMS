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
**          10/30/2007 mem - Now calling VerifyUpdateEnabled
**          10/09/2008 mem - Added T_Score_Inspect
**          06/02/2009 mem - Ported to DMS_Pipeline (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
    DBCC DBREINDEX (T_Job_Events, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Job_Step_Dependencies, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Job_Step_Events, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Job_Step_Processing_Log, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Job_Steps, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Jobs, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Jobs_History, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Log_Entries, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX (T_Shared_Results, '', 90)
    Set @TableCount = @TableCount + 1

    DBCC DBREINDEX ([T_Job_Parameters], '', 90)
    Set @TableCount = @TableCount + 1

    -----------------------------------------------------------
    -- Log the reindex
    -----------------------------------------------------------

    Set @message = 'Reindexed ' + Convert(varchar(12), @TableCount) + ' tables'
    Exec post_log_entry 'Normal', @message, 'reindex_database'


Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [Limited_Table_Write] AS [dbo]
GO
