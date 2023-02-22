/****** Object:  StoredProcedure [dbo].[DeleteOldEventsAndHistoricLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteOldEventsAndHistoricLogs]
/****************************************************
**
**  Desc:   Delete entries over 2 years old in
**          T_Job_Events, T_Job_Step_Events, T_Job_Step_Processing_Log, and T_Log_Entries
**
**          However, keep two weeks of events per year for historic reference reasons
**          (retain the first week of February and the first week of August)
**
**  Auth:   mem
**  Date:   06/08/2022 mem - Initial version
**          08/26/2022 mem - Use new column name in T_Log_Entries
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @yearFilter int = 0,        -- Use this to limit the number of rows to process to a single year
    @message varchar(1024) = '' output
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

    Declare @jobEventsMessage varchar(512) = ''
    Declare @jobStepEventsMessage varchar(512) = ''
    Declare @jobStepProcessingLogMessage varchar(512) = ''
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

    CREATE TABLE #Tmp_JobEventIDs (
        Event_ID   int NOT NULL,
        Entered datetime NOT NULL,
        PRIMARY KEY CLUSTERED ( Event_ID )
    )

    CREATE TABLE #Tmp_JobStepEventIDs (
        Event_ID   int NOT NULL,
        Entered datetime NOT NULL,
        PRIMARY KEY CLUSTERED ( Event_ID )
    )

    CREATE TABLE #Tmp_ProcessingLogEventIDs (
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
        Target_Table varchar(32) Not Null,
        Event_ID int NOT NULL,
        Job int NULL,
        Step int NULL,
        Target_State smallint NULL,
        Prev_Target_State smallint NULL,
        Processor varchar(64) Null,
        Entered datetime NULL,
        PRIMARY KEY CLUSTERED (Target_Table, Event_ID)
    )

    CREATE TABLE #Tmp_LogEntriesToDelete (
        Entry_ID int NOT NULL,
        Posted_By varchar(64) NULL,
        Entered datetime NOT NULL,
        [Type] varchar(32) NULL,
        Message varchar(512) NULL
    )

    ---------------------------------------------------
    -- Define the date threshold by subtracting 2 years from January 1 of this year
    ---------------------------------------------------

    Set @dateThreshold = DateAdd(Year, -2, DateTimeFromParts(Year(GetDate()), 1, 1, 0, 0, 0, 0))

    Set @thresholdDescription = 'using date threshold ' + Cast(Cast(@dateThreshold As Date) As varchar(24))

    If @yearFilter >= 1970
    Begin
        Set @thresholdDescription = @thresholdDescription + ' and year filter ' + Cast(@yearFilter As varchar(12))
    End

    ---------------------------------------------------
    -- Find items to delete in T_Job_Events
    ---------------------------------------------------

    INSERT INTO #Tmp_JobEventIDs( Event_ID, Entered )
    SELECT Event_ID, Entered
    FROM T_Job_Events
    WHERE Entered < @dateThreshold And
          Not (Month(Entered) In (2,8) And Day(Entered) Between 1 And 7) And
          (@yearFilter < 1970 Or Year(entered) = @yearFilter)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @eventsToDelete = @myRowcount

    If @eventsToDelete = 0
    Begin
        Set @jobEventsMessage = 'No job event entries were found ' + @thresholdDescription
    End
    Else
    Begin
        SELECT @eventsToDelete = Count(*),
               @eventIdMin = Min(Event_ID),
               @eventIdMax= Max(Event_ID)
        FROM #Tmp_JobEventIDs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Delete the old job events (preview if @infoOnly is non-zero)
        ---------------------------------------------------
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Events', T.Event_ID, T.Job, Null As Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
            FROM #Tmp_JobEventIDs S
                 INNER JOIN T_Job_Events T
                   ON S.Event_ID = T.Event_ID
            ORDER BY S.Event_ID

            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Events', T.Event_ID, T.Job, Null As Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
            FROM ( SELECT TOP 10 Event_ID
                   FROM #Tmp_JobEventIDs
                   ORDER BY Event_ID DESC
                 ) S
                 INNER JOIN T_Job_Events T
                   ON S.Event_ID = T.Event_ID
            ORDER BY T.Event_ID
        End
        Else
        Begin
            Delete From T_Job_Events
            Where Event_ID In (Select Event_ID From #Tmp_JobEventIDs)
        End

        If @infoOnly > 0
            Set @jobEventsMessage = 'Would delete '
        Else
            Set @jobEventsMessage = 'Deleted '

        Set @jobEventsMessage = @jobEventsMessage +
            Cast(@eventsToDelete As Varchar(12)) + ' old entries from T_Job_Events ' + @thresholdDescription + '; ' +
            'Event_ID range ' + Cast(@eventIdMin As varchar(12)) + ' to ' + Cast(@eventIdMax As varchar(12))

        If @infoOnly = 0 And @eventsToDelete > 0
        Begin
            Exec PostLogEntry 'Normal', @jobEventsMessage, 'DeleteOldEventsAndHistoricLogs'
        End
    End


    ---------------------------------------------------
    -- Find items to delete in T_Job_Step_Events
    ---------------------------------------------------

    INSERT INTO #Tmp_JobStepEventIDs( Event_ID, Entered )
    SELECT Event_ID, Entered
    FROM T_Job_Step_Events
    WHERE Entered < @dateThreshold And
          Not (Month(Entered) In (2,8) And Day(Entered) Between 1 And 7) And
          (@yearFilter < 1970 Or Year(entered) = @yearFilter)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @eventsToDelete = @myRowcount

    If @eventsToDelete = 0
    Begin
        Set @jobStepEventsMessage = 'No job step event entries were found ' + @thresholdDescription
    End
    Else
    Begin
        SELECT @eventsToDelete = Count(*),
               @eventIdMin = Min(Event_ID),
               @eventIdMax= Max(Event_ID)
        FROM #Tmp_JobStepEventIDs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Delete the old job step events (preview if @infoOnly is non-zero)
        ---------------------------------------------------
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Step_Events', T.Event_ID, T.Job, T.Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
            FROM #Tmp_JobStepEventIDs S
                 INNER JOIN T_Job_Step_Events T
                   ON S.Event_ID = T.Event_ID
            ORDER BY S.Event_ID

            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Step_Events', T.Event_ID, T.Job, T.Step, T.Target_State, T.Prev_Target_State, Null As Processor, T.Entered
            FROM ( SELECT TOP 10 Event_ID
                   FROM #Tmp_JobStepEventIDs
                   ORDER BY Event_ID DESC
                 ) S
                 INNER JOIN T_Job_Step_Events T
                   ON S.Event_ID = T.Event_ID
            ORDER BY T.Event_ID
        End
        Else
        Begin
            Delete From T_Job_Step_Events
            Where Event_ID In (Select Event_ID From #Tmp_JobStepEventIDs)
        End

        If @infoOnly > 0
            Set @jobStepEventsMessage = 'Would delete '
        Else
            Set @jobStepEventsMessage = 'Deleted '

        Set @jobStepEventsMessage = @jobStepEventsMessage +
            Cast(@eventsToDelete As Varchar(12)) + ' old entries from T_Job_Step_Events ' + @thresholdDescription + '; ' +
            'Event_ID range ' + Cast(@eventIdMin As varchar(12)) + ' to ' + Cast(@eventIdMax As varchar(12))

        If @infoOnly = 0 And @eventsToDelete > 0
        Begin
            Exec PostLogEntry 'Normal', @jobStepEventsMessage, 'DeleteOldEventsAndHistoricLogs'
        End
    End

    ---------------------------------------------------
    -- Find items to delete in T_Job_Step_Processing_Log
    ---------------------------------------------------

    INSERT INTO #Tmp_ProcessingLogEventIDs( Event_ID, Entered )
    SELECT Event_ID, Entered
    FROM T_Job_Step_Processing_Log
    WHERE Entered < @dateThreshold And
          Not (Month(Entered) In (2,8) And Day(Entered) Between 1 And 7) And
          (@yearFilter < 1970 Or Year(entered) = @yearFilter)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @eventsToDelete = @myRowcount

    If @eventsToDelete = 0
    Begin
        Set @jobStepProcessingLogMessage = 'No job step processing log entries were found ' + @thresholdDescription
    End
    Else
    Begin
        SELECT @eventsToDelete = Count(*),
               @eventIdMin = Min(Event_ID),
               @eventIdMax= Max(Event_ID)
        FROM #Tmp_ProcessingLogEventIDs
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Delete the old processing log entries (preview if @infoOnly is non-zero)
        ---------------------------------------------------
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly > 0
        Begin
            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Step_Processing_Log', T.Event_ID, T.Job, T.Step, Null As Target_State, Null As Prev_Target_State, T.Processor, T.Entered
            FROM #Tmp_ProcessingLogEventIDs S
                 INNER JOIN T_Job_Step_Processing_Log T
                   ON S.Event_ID = T.Event_ID
            ORDER BY S.Event_ID

            INSERT INTO #Tmp_EventsToDelete (Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered)
            SELECT TOP 10 'T_Job_Step_Processing_Log', T.Event_ID, T.Job, T.Step, Null As Target_State, Null As Prev_Target_State, T.Processor, T.Entered
            FROM ( SELECT TOP 10 Event_ID
                   FROM #Tmp_ProcessingLogEventIDs
                   ORDER BY Event_ID DESC
                 ) S
                 INNER JOIN T_Job_Step_Processing_Log T
                   ON S.Event_ID = T.Event_ID
            ORDER BY T.Event_ID
        End
        Else
        Begin
            Delete From T_Job_Step_Processing_Log
            Where Event_ID In (Select Event_ID From #Tmp_ProcessingLogEventIDs)
        End

        If @infoOnly > 0
            Set @jobStepProcessingLogMessage = 'Would delete '
        Else
            Set @jobStepProcessingLogMessage = 'Deleted '

        Set @jobStepProcessingLogMessage = @jobStepProcessingLogMessage +
            Cast(@eventsToDelete As Varchar(12)) + ' old entries from T_Job_Step_Processing_Log ' + @thresholdDescription + '; ' +
            'Event_ID range ' + Cast(@eventIdMin As varchar(12)) + ' to ' + Cast(@eventIdMax As varchar(12))

        If @infoOnly = 0 And @eventsToDelete > 0
        Begin
            Exec PostLogEntry 'Normal', @jobStepProcessingLogMessage, 'DeleteOldEventsAndHistoricLogs'
        End
    End

    If @infoOnly > 0
    Begin
        SELECT Target_Table, Event_ID, Job, Step, Target_State, Prev_Target_State, Processor, Entered
        FROM #Tmp_EventsToDelete
        ORDER BY Target_Table, Event_ID
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
            INSERT INTO #Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, [Type], Message)
            SELECT TOP 10 T.Entry_ID, T.Posted_By, T.Entered, T.[Type], T.Message
            FROM #Tmp_HistoricLogIDs S
                 INNER JOIN T_Log_Entries T
                   ON S.Entry_ID = T.Entry_ID
            ORDER BY T.Entry_ID

            INSERT INTO #Tmp_LogEntriesToDelete (Entry_ID, Posted_By, Entered, [Type], Message)
            SELECT TOP 10 T.Entry_ID, T.Posted_By, T.Entered, T.[Type], T.Message
            FROM ( SELECT TOP 10 Entry_ID
                   FROM #Tmp_HistoricLogIDs
                   ORDER BY Entry_ID DESC
                 ) S
                 INNER JOIN T_Log_Entries T
                   ON S.Entry_ID = T.Entry_ID
            ORDER BY T.Entry_ID

            SELECT Entry_ID, Posted_By, Entered, [Type], Message
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

    If Len(@jobEventsMessage) > 0
    Begin
        Print @jobEventsMessage
        Set @message = dbo.AppendToText(@message, @jobEventsMessage, 0, '; ', 1024)
    End

    If Len(@jobStepEventsMessage) > 0
    Begin
        Print @jobStepEventsMessage
        Set @message = dbo.AppendToText(@message, @jobStepEventsMessage, 0, '; ', 1024)
    End

    If Len(@jobStepProcessingLogMessage) > 0
    Begin
        Print @jobStepProcessingLogMessage
        Set @message = dbo.AppendToText(@message, @jobStepProcessingLogMessage, 0, '; ', 1024)
    End

    If Len(@historicLogMessage) > 0
    Begin
        Print @historicLogMessage
        Set @message = dbo.AppendToText(@message, @historicLogMessage, 0, '; ', 1024)
    End

    Return @myError

GO
