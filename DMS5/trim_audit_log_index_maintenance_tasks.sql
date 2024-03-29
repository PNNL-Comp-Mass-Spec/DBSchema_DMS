/****** Object:  StoredProcedure [dbo].[trim_audit_log_index_maintenance_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[trim_audit_log_index_maintenance_tasks]
/****************************************************
**
**  Desc:
**      Trims entries from table SchemaChangeLog related to
**      automated index maintenance tasks
**
**      Also removes old Alter Object entries
**      ALTER_PROCEDURE, ALTER_TABLE, ALTER_VIEW, etc.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/27/2016
**          10/28/2016 mem - Auto-determine the LoginName to filter on
**          08/30/2017 mem - Remove old Alter Procedure, Alter Table, Alter View, etc. entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @databaseFilter varchar(128) = '',      -- Empty string for current database, wildcard with % for multiple databases
    @islandsToUpdate int = 0,               -- Set to a positive number to limit the number of updates
    @exclusionWeeks int = 2,                -- Exclude events from the most recent x weeks
    @infoOnly tinyint = 1,                  -- 0 to make changes, 1 to see affected rows, 2 to preview the updates in detail
    @previewSql tinyint = 0,
    @message varchar(255) = '' output
)
AS
    SET NOCOUNT ON

    Declare @myRowCount int
    Declare @myError int
    set @myRowCount = 0
    set @myError = 0

    Declare @Sql nvarchar(2048)
    Declare @SqlParams nvarchar(2048)
    Declare @MatchCount int
    Declare @LoginName varchar(128)

    Declare @SchemaChangeLogTable nvarchar(128)
    Declare @CreateDateFilter nvarchar(128)
    Declare @SqlEventFilter nvarchar(255)

    Declare @currentIsland int = -1
    Declare @StartSeqNo int = 0
    Declare @EndSeqNo int = -1
    Declare @ItemsInRange int = 0
    Declare @islandsProcessed int = 0

    Declare @continue tinyint = 1

    ---------------------------------------------------
    -- Validate the Inputs
    ---------------------------------------------------

    Set @databaseFilter = IsNull(@databaseFilter, '')
    Set @islandsToUpdate = IsNull(@islandsToUpdate, 0)
    Set @exclusionWeeks = IsNull(@exclusionWeeks, 2)
    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @previewSql = IsNull(@previewSql, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Create two temporary tables
    ---------------------------------------------------

    CREATE TABLE #Tmp_DatabasesToProcess (
        Database_ID int,
        DatabaseName sysname
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_DatabasesToProcess ON #Tmp_DatabasesToProcess (Database_ID)

    CREATE TABLE #Tmp_LogEntriesToUpdate (
        IslandNumber int,
        StartSeqNo int,
        EndSeqNo int,
        ItemsInRange int,
        Date_Avg datetime null,
        IgnoreIsland tinyint not null default 0
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_LogEntriesToUpdate ON #Tmp_LogEntriesToUpdate (IslandNumber)

    CREATE TABLE #Tmp_AlterEventsToRemove (
        SchemaChangeLogID int not null
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_AlterEventsToRemove ON #Tmp_AlterEventsToRemove (SchemaChangeLogID)

    ---------------------------------------------------
    -- Find databases to process
    ---------------------------------------------------
    --
    If @databaseFilter = ''
        Set @databaseFilter = Db_Name()

    INSERT INTO #Tmp_DatabasesToProcess(Database_ID, DatabaseName)
    SELECT database_id, name
    FROM sys.databases
    WHERE name LIKE @databaseFilter
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Not Exists (Select * From #Tmp_DatabasesToProcess)
    Begin
        Set @message = 'No databases matched search spec "' + @databaseFilter + '"'
        Goto Done
    End

    Declare @currentDbID int = 0
    Declare @currentDbName sysname
    Declare @continueDBs tinyint = 1

    While @continueDBs = 1
    Begin -- <a>

        SELECT TOP 1 @currentDbID = Database_ID, @currentDbName = DatabaseName
        FROM #Tmp_DatabasesToProcess
        WHERE Database_ID > @currentDbID
        ORDER BY Database_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @continueDBs = 0
        End
        Else
        Begin -- <b>

            Set @Sql = 'SELECT @MatchCount = COUNT(*) FROM [' + @currentDbName + '].sys.tables WHERE name = ''SchemaChangeLog'''
            Set @SqlParams = '@MatchCount int output'
            Set @MatchCount = 0

            If @previewSql > 0
                Print @Sql

            Exec @myError = sp_executesql @Sql, @SqlParams, @MatchCount output

            If @MatchCount = 0
            Begin
                Print 'Skipping ' + @currentDbName + ' since table SchemaChangeLog not found'
                Goto NextDatabase
            End

            Print ''
            Print 'Processing ' + @currentDbName

            Set @SchemaChangeLogTable = '[' + @currentDbName + '].dbo.SchemaChangeLog'

            ---------------------------------------------------
            -- Determine the login name most often associated with ALTER_INDEX and UPDATE_STATISTICS audit events
            -- This user will typically be pnl\msdadmin or pnl\mtsadmin
            ---------------------------------------------------

            Set @Sql = ''
            Set @Sql = @Sql + ' SELECT TOP 1 @LoginName = LoginName'
            Set @Sql = @Sql + ' FROM ' + @SchemaChangeLogTable
            Set @Sql = @Sql + ' WHERE (SQLEvent IN (''ALTER_INDEX'', ''UPDATE_STATISTICS''))'
            Set @Sql = @Sql + ' GROUP BY LoginName'
            Set @Sql = @Sql + ' ORDER BY COUNT(*) DESC'

            Set @SqlParams = '@LoginName varchar(128) output'
            Set @MatchCount = 0

            If @previewSql > 0
                Print @Sql

            Exec @myError = sp_executesql @Sql, @SqlParams, @LoginName output

            If @infoOnly > 0 Or @previewSql > 0
                Print 'LoginName associated with ALTER_INDEX and UPDATE_STATISTICS events: ' + @LoginName

            ---------------------------------------------------
            -- Find "islands" of log entries, i.e. places where
            -- the same SQLEvent is logged sequentially
            --
            -- Uses code from https://www.simple-talk.com/sql/t-sql-programming/the-sql-of-gaps-and-islands-in-sequences/
            -- which uses "Islands Solution #3" from book "SQL MVP Deep Dives"
            --
            -- Filter on islands with more than 3 rows because when this procedure consolidates islands, it
            -- removes all but the first and last log entry, but inserts a new log entry just after the
            -- first log entry with a message describing the number of log entries that existed between the
            -- island end points prior to
            ---------------------------------------------------

            TRUNCATE TABLE #Tmp_LogEntriesToUpdate

            Set @Sql = ''
            Set @Sql = @Sql + ' INSERT INTO #Tmp_LogEntriesToUpdate( IslandNumber, StartSeqNo, EndSeqNo, ItemsInRange )'
            Set @Sql = @Sql + ' SELECT rn,'
            Set @Sql = @Sql +        ' StartSeqNo = MIN(SchemaChangeLogID),'
            Set @Sql = @Sql +        ' EndSeqNo = MAX(SchemaChangeLogID),'
            Set @Sql = @Sql +        ' Count(*) AS ItemsInRange'
            Set @Sql = @Sql +        ' FROM ( SELECT SchemaChangeLogID,'
            Set @Sql = @Sql +               ' SchemaChangeLogID - ROW_NUMBER() OVER ( ORDER BY SchemaChangeLogID ) AS rn'
            Set @Sql = @Sql +        ' FROM ' + @SchemaChangeLogTable
            Set @Sql = @Sql +        ' WHERE (LoginName = ''' + @LoginName + ''') AND'
            Set @Sql = @Sql +        ' (SQLEvent IN (''ALTER_INDEX'', ''UPDATE_STATISTICS'')) ) RankQ'
            Set @Sql = @Sql +        ' GROUP BY rn'
            Set @Sql = @Sql +        ' HAVING Count(*) > 3'
            --

            If @previewSql > 0
                Print @Sql

            exec sp_executesql @Sql
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            ---------------------------------------------------
            -- Determine the average date of the log entries
            -- associated with each island
            ---------------------------------------------------
            --
            Set @Sql = ''
            Set @Sql = @Sql + ' UPDATE #Tmp_LogEntriesToUpdate'
            Set @Sql = @Sql + ' SET Date_Avg = DateQ.Date_Avg'
            Set @Sql = @Sql + ' FROM #Tmp_LogEntriesToUpdate Target'
            Set @Sql = @Sql + '     INNER JOIN ( SELECT IslandNumber,'
            Set @Sql = @Sql + '                         Cast(Avg(Cast(SCL.CreateDate As Float)) As DateTime) AS Date_Avg'
            Set @Sql = @Sql + '                 FROM #Tmp_LogEntriesToUpdate U'
            Set @Sql = @Sql + '                     INNER JOIN ' + @SchemaChangeLogTable + ' SCL'
            Set @Sql = @Sql + '                         ON SCL.SchemaChangeLogID BETWEEN U.StartSeqNo AND U.EndSeqNo'
            Set @Sql = @Sql + '                 GROUP BY IslandNumber'
            Set @Sql = @Sql + '                 ) DateQ'
            Set @Sql = @Sql + '     ON Target.IslandNumber = DateQ.IslandNumber'

            If @previewSql > 0
                Print @Sql

            exec sp_executesql @Sql
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @exclusionWeeks > 0
            Begin
                -- Flag entries in #Tmp_LogEntriesToUpdate where
                -- the average date of the log entries is within @exclusionWeeks weeks
                --
                UPDATE #Tmp_LogEntriesToUpdate
                Set IgnoreIsland = 1
                WHERE Date_Avg >= DateAdd(week, -@exclusionWeeks, GetDate())
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End


            ---------------------------------------------------
            -- Find old alter object entries to remove
            -- We keep all of the events in recent weeks (determined via @exclusionWeeks)
            -- Plus also the last two change events prior to that; grouping change events by day
            ---------------------------------------------------
            --
            TRUNCATE TABLE #Tmp_AlterEventsToRemove

            Set @CreateDateFilter = 'DateAdd(week, -' + Cast(@exclusionWeeks as varchar(6)) + ', GetDate())'
            Set @SqlEventFilter = 'SQLEvent IN (''ALTER_PROCEDURE'', ''ALTER_TABLE'', ''ALTER_FUNCTION'', ''ALTER_VIEW'', ''ALTER_TRIGGER'', ''ALTER_INDEX'')'

            Set @Sql = ''
            Set @Sql = @Sql + ' INSERT INTO #Tmp_AlterEventsToRemove( SchemaChangeLogID )'
            Set @Sql = @Sql + ' SELECT SchemaChangeLogID'
            Set @Sql = @Sql + ' FROM ' + @SchemaChangeLogTable
            Set @Sql = @Sql + ' WHERE ' + @SqlEventFilter + ' AND '
            Set @Sql = @Sql + '       CreateDate < ' + @CreateDateFilter + ' AND '
            Set @Sql = @Sql + '       NOT SchemaChangeLogID IN '
            Set @Sql = @Sql + '           ( SELECT SchemaChangeLogID'
            Set @Sql = @Sql + '             FROM ( SELECT ObjectName,'
            Set @Sql = @Sql + '                           SchemaChangeLogID,'
            Set @Sql = @Sql + '                           Row_Number() OVER ( PARTITION BY ObjectName '
            Set @Sql = @Sql + '                                               ORDER BY SchemaChangeLogID DESC ) AS DateRank'
            Set @Sql = @Sql + '                    FROM ( SELECT ObjectName,'
            Set @Sql = @Sql + '                                  Cast(CreateDate AS date) AS CreateDate,'
            Set @Sql = @Sql + '                                  SchemaChangeLogID,'
            Set @Sql = @Sql + '                                  Row_Number() OVER ( PARTITION BY ObjectName, Cast(CreateDate AS date) '
            Set @Sql = @Sql + '                                                      ORDER BY SchemaChangeLogID DESC ) AS SameDayRank'
            Set @Sql = @Sql + '                           FROM ' + @SchemaChangeLogTable
            Set @Sql = @Sql + '                           WHERE ' + @SqlEventFilter + ' AND '
            Set @Sql = @Sql + '                                 CreateDate < ' + @CreateDateFilter
            Set @Sql = @Sql + '                         ) RankQ'
            Set @Sql = @Sql + '                   WHERE SameDayRank = 1 '
            Set @Sql = @Sql + '                  ) OuterRankQ'
            Set @Sql = @Sql + '             WHERE DateRank <= 2 )'

            If @previewSql > 0
                Print @Sql

            exec sp_executesql @Sql
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            If @infoOnly = 1
            Begin -- <c1>

                If Not Exists (Select * FROM #Tmp_LogEntriesToUpdate)
                Begin
                    If @previewSql = 0
                    Begin
                        If @exclusionWeeks = 0
                            SELECT @currentDbName as DB,
                                'No log entries to remove' as Message,
                                'Date filter not applied since @exclusionWeeks = 0' as Detail

                        Else
                            SELECT @currentDbName as DB,
                                'No log entries to remove' as Message,
                                'No log entry islands entered before ' + Cast(DateAdd(WEEK, -@exclusionWeeks, GetDate()) as varchar(30)) as Detail
                    End
                End
                Else
                Begin -- <d1>
                    ---------------------------------------------------
                    -- Preview the islands
                    ---------------------------------------------------
                    --
                    SELECT @currentDbName as DB, *
                    FROM #Tmp_LogEntriesToUpdate U
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    ---------------------------------------------------
                    -- Preview the details of the islands
                    ---------------------------------------------------
                    --
                    Set @sql = ''
                    Set @sql = @Sql + ' SELECT ''' + @currentDbName + ''' AS DB, U.IslandNumber, SCL.*'
                    Set @sql = @Sql + ' FROM #Tmp_LogEntriesToUpdate U'
                    Set @sql = @Sql +      ' INNER JOIN ' + @SchemaChangeLogTable + ' SCL'
                    Set @sql = @Sql + ' ON SCL.SchemaChangeLogID BETWEEN U.StartSeqNo AND U.EndSeqNo'
                    Set @sql = @Sql + ' ORDER BY SCL.SchemaChangeLogID'

                    If @previewSql > 0
                        Print @Sql
                    Else
                        exec sp_executesql @Sql
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                End -- </d1>

                If Not Exists (Select * FROM #Tmp_AlterEventsToRemove)
                Begin
                    If @previewSql = 0
                    Begin
                        If @exclusionWeeks = 0
                            SELECT @currentDbName as DB,
                                'No Alter Object entries to remove' as Message,
                                'Date filter not applied since @exclusionWeeks = 0' as Detail

                        Else
                            SELECT @currentDbName as DB,
                                'No Alter Object entries to remove' as Message,
                                'No entries to remove prior to ' + Cast(DateAdd(WEEK, -@exclusionWeeks, GetDate()) as varchar(30)) as Detail
                    End
                End
                Else
                Begin
                    ---------------------------------------------------
                    -- Preview the entries to remove
                    ---------------------------------------------------
                    --
                    Set @sql = ''
                    Set @sql = @Sql + ' SELECT ''' + @currentDbName + ''' AS DB, ''Old entry to delete'' AS Action, SCL.*'
                    Set @sql = @Sql + ' FROM #Tmp_AlterEventsToRemove R'
                    Set @sql = @Sql +      ' INNER JOIN ' + @SchemaChangeLogTable + ' SCL'
                    Set @sql = @Sql + ' ON SCL.SchemaChangeLogID = R.SchemaChangeLogID'
                    Set @sql = @Sql + ' ORDER BY SCL.SchemaChangeLogID'

                    If @previewSql > 0
                        Print @Sql
                    Else
                        exec sp_executesql @Sql
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                End

            End -- </c1>
            Else
            Begin -- <c2>
                If Not Exists (Select * FROM #Tmp_LogEntriesToUpdate WHERE IgnoreIsland = 0)
                Begin
                    If @previewSql = 0
                    Begin
                        If @exclusionWeeks = 0
                            Print 'No log entries to remove; date filter not applied since @exclusionWeeks = 0'
                        Else
                            Print 'No log entries to remove; no log entry islands entered before ' + Cast(DateAdd(WEEK, -@exclusionWeeks, GetDate()) as varchar(30))
                    End
                End

                ---------------------------------------------------
                -- Step through the islands and either consolidate rows or preview the consolidation
                ---------------------------------------------------
                --
                Set @currentIsland = -1
                Set @StartSeqNo = 0
                Set @EndSeqNo = -1
                Set @ItemsInRange = 0
                Set @islandsProcessed = 0

                Set @continue = 1

                While @continue = 1
                Begin -- <d2>
                    SELECT TOP 1 @currentIsland = IslandNumber,
                                @StartSeqNo = StartSeqNo,
                                @EndSeqNo = EndSeqNo,
                                @ItemsInRange = ItemsInRange
                    FROM #Tmp_LogEntriesToUpdate
                    WHERE IgnoreIsland = 0 AND IslandNumber > @currentIsland
                    ORDER BY IslandNumber
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount = 0
                    Begin
                        Set @continue = 0
                    End
                    Else
                    Begin -- <e>

                        If @infoOnly = 0
                        Begin -- <f1>
                            Set @SQL = ''
                            Set @SQL = @SQL + ' DELETE FROM ' + @SchemaChangeLogTable
                            Set @SQL = @SQL + ' WHERE SchemaChangeLogID BETWEEN ' + Cast(@StartSeqNo + 2 AS nvarchar(18)) + ' AND ' + Cast(@EndSeqNo - 1 as nvarchar(18))

                            If @previewSql > 0
                                Print @Sql
                            Else
                                exec sp_executesql @Sql
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            Set @SQL = ''
                            Set @SQL = @SQL + ' UPDATE ' + @SchemaChangeLogTable
                            Set @SQL = @SQL + ' SET LoginName = Suser_Sname(),'
                            Set @SQL = @SQL +     ' SQLEvent = ''Consolidate_Audit_Events'','
                            Set @SQL = @SQL +     ' ObjectName = ''SchemaChangeLog'','
                            Set @SQL = @SQL +     ' SQLCmd = ''Consolidated ' + Cast(@ItemsInRange - 2 as nvarchar(18)) + ' index maintenance task audit events'','
                            Set @SQL = @SQL +     ' XmlEvent = Cast(''<Consolidate />'' as xml)'
                            Set @SQL = @SQL + ' WHERE SchemaChangeLogID = ' + Cast(@StartSeqNo + 1 as nvarchar(18))

                            If @previewSql > 0
                                Print @Sql
                            Else
                                exec sp_executesql @Sql
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                        End -- </f1>
                        Else
                        Begin -- <f2>
                            SELECT @currentDbName as DB,
                                'DELETE FROM SchemaChangeLog' as Task,
                                'WHERE SchemaChangeLogID BETWEEN ' + Cast(@StartSeqNo + 2 as varchar(9)) + ' AND ' + Cast(@EndSeqNo - 1 as varchar(9)) as Range

                            SELECT @currentDbName as DB,
                                'UPDATE SchemaChangeLog SET SQLEvent = "Consolidate_Audit_Events", SQLCmd = "Consolidate ' + Cast(@ItemsInRange - 2 as varchar(9)) + ' index maintenance task audit events"' as Task,
                                'WHERE SchemaChangeLogID = ' + Cast(@StartSeqNo + 1 as varchar(9))

                        End -- </f2>

                        Set @islandsProcessed = @islandsProcessed + 1
                        If @islandsToUpdate > 0 And @islandsProcessed = @islandsToUpdate
                            Set @continue = 0

                    End -- </e>
                End -- </d2>

                Set @SQL = ''
                Set @SQL = @SQL + ' DELETE ' + @SchemaChangeLogTable
                Set @SQL = @SQL + ' FROM ' + @SchemaChangeLogTable + ' Target'
                Set @SQL = @SQL +     ' INNER JOIN #Tmp_AlterEventsToRemove Src '
                Set @SQL = @SQL +     ' ON Target.SchemaChangeLogID = Src.SchemaChangeLogID '
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @previewSql > 0
                    Print @Sql
                Else
                    exec sp_executesql @Sql

            End -- </c2>

        End -- </b>

NextDatabase:

    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

Done:

If @message <> ''
Begin
    Select @message as Message
End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[trim_audit_log_index_maintenance_tasks] TO [DDL_Viewer] AS [dbo]
GO
