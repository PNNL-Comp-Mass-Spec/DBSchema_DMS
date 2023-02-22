/****** Object:  StoredProcedure [dbo].[DeleteOldEventsAndHistoricLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteOldEventsAndHistoricLogs]
/****************************************************
**
**  Desc:   Delete entries over 5 years old in T_Event_Log and T_Log_Entries
**
**          However, keep two weeks of events per year for historic reference reasons
**          (retain the first week of February and the first week of August)
**
**  Auth:   mem
**  Date:   06/08/2022 mem - Initial version
**          06/09/2022 mem - Rename T_Historic_Log_Entries to T_Log_Entries
**          08/26/2022 mem - Use new column name in T_Log_Entries
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @yearFilter int = 0,        -- Use this to limit the number of rows to process to a single year
    @message varchar(512)='' output
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @dateThreshold datetime
    Declare @thresholdDescription varchar(128)

    Declare @eventsToDelete Int
    Declare @eventIdMin Int
    Declare @eventIdMax Int

    Declare @logEntriesToDelete Int
    Declare @entryIdMin Int
    Declare @entryIdMax Int

    Declare @eventMessage varchar(512) = ''
    Declare @historicLogMessage varchar(512) = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @yearFilter = IsNull(@yearFilter, 0)

    Set @message = ''

    ---------------------------------------------------
    -- Create temp tables to hold the IDs of the items to delete
    ---------------------------------------------------

    CREATE TABLE #Tmp_EventLogIDs (
        Event_ID   int NOT NULL,
        Entered datetime NOT NULL,
        PRIMARY KEY CLUSTERED ( Event_ID )
    )

    CREATE TABLE #Tmp_HistoricLogIDs (
        Entry_ID   int NOT NULL,
        Entered datetime NOT NULL,
        PRIMARY KEY CLUSTERED ( Entry_ID, Entered )
    )

    CREATE TABLE #Tmp_EventsToDelete (
        Event_ID int NOT NULL,
        Target_Type int NULL,
        Target_ID int NULL,
        Target_State smallint NULL,
        Prev_Target_State smallint NULL,
        Entered datetime NULL,
        PRIMARY KEY CLUSTERED ( Event_ID)
    )

    CREATE TABLE #Tmp_LogEntriesToDelete (
        Entry_ID int NOT NULL,
        Posted_By varchar(64) NULL,
        Entered datetime NOT NULL,
        [Type] varchar(32) NULL,
        Message varchar(512) NULL,
        DBName varchar(64) NULL
    )

    ---------------------------------------------------
    -- Define the date threshold by subtracting five years from January 1 of this year
    ---------------------------------------------------

    Set @dateThreshold = DateAdd(Year, -5, DateTimeFromParts(Year(GetDate()), 1, 1, 0, 0, 0, 0))

    Set @thresholdDescription = 'using date threshold ' + Cast(Cast(@dateThreshold As Date) As varchar(24))

    If @yearFilter >= 1970
    Begin
        Set @thresholdDescription = @thresholdDescription + ' and year filter ' + Cast(@yearFilter As varchar(12))
    End

    ---------------------------------------------------
    -- Find event log items to delete
    ---------------------------------------------------

    INSERT INTO #Tmp_EventLogIDs( Event_ID, Entered )
    SELECT Event_ID, Entered
    FROM T_Event_Log
    WHERE Entered < @dateThreshold And
          Not (Month(Entered) In (2,8) And Day(Entered) Between 1 And 7) And
          (@yearFilter < 1970 Or Year(entered) = @yearFilter)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @eventsToDelete = @myRowcount

    If @eventsToDelete = 0
    Begin
        Set @eventMessage = 'No event log entries were found ' + @thresholdDescription
    End
    Else
    Begin
        SELECT @eventsToDelete = Count(*),
               @eventIdMin = Min(Event_ID),
               @eventIdMax= Max(Event_ID)
        FROM #Tmp_EventLogIDs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Delete the old events (preview if @infoOnly is non-zero)
        ---------------------------------------------------
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            INSERT INTO #Tmp_EventsToDelete (Event_ID, Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
            SELECT TOP 10 T.Event_ID, T.Target_Type, T.Target_ID, T.Target_State, T.Prev_Target_State, T.Entered
            FROM #Tmp_EventLogIDs S
                 INNER JOIN T_Event_Log T
                   ON S.Event_ID = T.Event_ID
            ORDER BY S.Event_ID

            INSERT INTO #Tmp_EventsToDelete (Event_ID, Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
            SELECT TOP 10 T.Event_ID, T.Target_Type, T.Target_ID, T.Target_State, T.Prev_Target_State, T.Entered
            FROM ( SELECT TOP 10 Event_ID
                   FROM #Tmp_EventLogIDs
                   ORDER BY Event_ID DESC
                 ) S
                 INNER JOIN T_Event_Log T
                   ON S.Event_ID = T.Event_ID
            ORDER BY T.Event_ID

            SELECT Event_ID, Target_Type, Target_ID, Target_State, Prev_Target_State, Entered
            FROM #Tmp_EventsToDelete
            ORDER BY Event_ID
        End
        Else
        Begin
            Delete From T_Event_Log
            Where Event_ID In (Select Event_ID From #Tmp_EventLogIDs)
        End

        If @infoOnly > 0
            Set @eventMessage = 'Would delete '
        Else
            Set @eventMessage = 'Deleted '

        Set @eventMessage = @eventMessage +
            Cast(@eventsToDelete As Varchar(12)) + ' old entries from T_Event_Log ' + @thresholdDescription + '; ' +
            'Event_ID range ' + Cast(@eventIdMin As varchar(12)) + ' to ' + Cast(@eventIdMax As varchar(12))

        If @infoOnly = 0 And @eventsToDelete > 0
        Begin
            Exec PostLogEntry 'Normal', @eventMessage, 'DeleteOldEventsAndHistoricLogs'
        End
    End


    ---------------------------------------------------
    -- Find historic log items to delete
    ---------------------------------------------------

    INSERT INTO #Tmp_HistoricLogIDs( Entry_ID, Entered )
    SELECT Entry_ID, Entered
    FROM T_Log_Entries
    WHERE Entered < @dateThreshold And
          Not (Month(Entered) In (2,8) And Day(Entered) Between 1 And 7) And
          (@yearFilter < 1970 Or Year(Entered) = @yearFilter)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @logEntriesToDelete = @myRowcount

    If @logEntriesToDelete = 0
    Begin
        Set @historicLogMessage = 'No historic log entries were found ' +  + @thresholdDescription
    End
    Else
    Begin
        SELECT @logEntriesToDelete = Count(*),
               @entryIdMin = Min(Entry_ID),
               @entryIdMax= Max(Entry_ID)
        FROM #Tmp_HistoricLogIDs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Delete the old log entries (preview if @infoOnly is non-zero)
        ---------------------------------------------------
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            INSERT INTO #Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, [Type], Message, DBName)
            SELECT TOP 10 T.Entry_ID, T.Posted_By, T.Entered, T.[Type], T.Message, T.DBName
            FROM #Tmp_HistoricLogIDs S
                 INNER JOIN T_Log_Entries T
                   ON S.Entry_ID = T.Entry_ID
            ORDER BY T.Entry_ID

            INSERT INTO #Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, [Type], Message, DBName)
            SELECT TOP 10 T.Entry_ID, T.Posted_By, T.Entered, T.[Type], T.Message, T.DBName
            FROM ( SELECT TOP 10 Entry_ID
                   FROM #Tmp_HistoricLogIDs
                   ORDER BY Entry_ID DESC
                 ) S
                 INNER JOIN T_Log_Entries T
                   ON S.Entry_ID = T.Entry_ID
            ORDER BY T.Entry_ID

            SELECT Entry_ID, Posted_By, Entered, [Type], Message, DBName
            FROM #Tmp_LogEntriesToDelete
            ORDER By Entry_ID
        End
        Else
        Begin
            Delete From T_Log_Entries
            Where Entry_ID In (Select Entry_ID From #Tmp_HistoricLogIDs)
        End

        If @infoOnly > 0
            Set @historicLogMessage = 'Would delete '
        Else
            Set @historicLogMessage = 'Deleted '

        Set @historicLogMessage = @historicLogMessage +
            Cast(@logEntriesToDelete As Varchar(12)) + ' old entries from T_Log_Entries ' + @thresholdDescription + '; ' +
            'Entry_ID range ' + Cast(@entryIdMin As varchar(12)) + ' to ' + Cast(@entryIdMax As varchar(12))

        If @infoOnly = 0 And @logEntriesToDelete > 0
        Begin
            Exec PostLogEntry 'Normal', @historicLogMessage, 'DeleteOldEventsAndHistoricLogs'
        End
    End

Done:
    If @myError <> 0
    Begin
        Set @message = 'Error in DeleteOldEventsAndHistoricLogs'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @infoOnly = 0
            Exec PostLogEntry 'Error', @message, 'DeleteOldEventsAndHistoricLogs'

        Print @message
    End

    If Len(@eventMessage) > 0
    Begin
        Print @eventMessage
        Set @message = dbo.AppendToText(@message, @eventMessage, 0, '; ', 1024)
    End

    If Len(@historicLogMessage) > 0
    Begin
        Print @historicLogMessage
        Set @message = dbo.AppendToText(@message, @historicLogMessage, 0, '; ', 1024)
    End

    Return @myError

GO
