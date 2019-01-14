/****** Object:  StoredProcedure [dbo].[ConsolidateLogMessages] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[ConsolidateLogMessages]
/****************************************************
** 
**  Desc:   Deletes duplicate messages in T_Log_Entries,
**          keeping the first and last message 
**          (or, optionally only the first message)
**
**  Auth:   mem
**  Date:   01/14/2019 mem - Initial version
**    
*****************************************************/
(
    @messageType varchar(64) = 'Error',
    @messageFilter varchar(128) = '',           -- Optional filter for the message text; will auto-add % wildcards if it does not contain a % and no messages are matched
    @keepFirstMessageOnly tinyint = 0,          -- When 0, keep the first and last message; when 1, only keep the first message
    @changeErrorsToErrorIgnore tinyint = 1,     -- When 1, if @messageType is 'Error' will update messages in T_Log_Entries to have type 'ErrorIgnore' (if duplicates are removed)
    @infoOnly tinyint = 1
)
As
    Set XACT_ABORT, nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(256) = ''
    Declare @deletedMessageCount int = 0
    Declare @duplicateMessageCount int = 0

    Declare @statusKeep varchar(24)
    Declare @statusDelete varchar(24)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try
        
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        
        Set @messageType = Ltrim(Rtrim(IsNull(@messageType, '')))
        Set @messageFilter = IsNull(@messageFilter, '')
        Set @keepFirstMessageOnly = IsNull(@keepFirstMessageOnly, 0)
        Set @changeErrorsToErrorIgnore = IsNull(@changeErrorsToErrorIgnore, 1)
        Set @infoOnly = IsNull(@infoOnly, 1)

        If Len(@messageType) = 0
        Begin
            Print '@messageType cannot be empty'
            Goto Done
        End

        CREATE TABLE #Tmp_DuplicateMessages (
            [Message] varchar(1024),
            [Entry_ID_First] int,
            [Entry_ID_Last] int
        )

        CREATE TABLE #Tmp_MessagesToDelete (            
            [Entry_ID] int
        )

        ----------------------------------------------------
        -- Find duplicate log entries
        ----------------------------------------------------
        --
        If @messageFilter = ''
        Begin
            INSERT INTO #Tmp_DuplicateMessages( [message], [Entry_ID_First], [Entry_ID_Last] )
            SELECT [message], Min(Entry_ID), Max(Entry_ID)
            FROM T_Log_Entries
            WHERE [type] = @messageType
            GROUP BY [message]
            HAVING Count(*) >= 2
            --
	        SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            Declare @retriesRemaining int = 2
            While @retriesRemaining > 0
            Begin
                INSERT INTO #Tmp_DuplicateMessages( [message], [Entry_ID_First], [Entry_ID_Last] )
                SELECT [message], Min(Entry_ID), Max(Entry_ID)
                FROM T_Log_Entries
                WHERE [type] = @messageType AND
                      [message] LIKE @messageFilter
                GROUP BY [message]
                HAVING Count(*) >= 2
                --
	            SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0 Or @messageFilter Like '%[%]%'
                    Set @retriesRemaining = 0
                Else
                Begin
                    Set @messageFilter = '%' + @messageFilter + '%'
                    Set @retriesRemaining = @retriesRemaining - 1
                End

            End
        End

        ----------------------------------------------------
        -- Find the messages that should be deleted,
        -- keeping only the first one if @keepFirstMessageOnly non-zero
        ----------------------------------------------------
        --     
        If @keepFirstMessageOnly = 0
        Begin
            INSERT INTO #Tmp_MessagesToDelete
            SELECT L.Entry_ID
            FROM T_Log_Entries L
                 INNER JOIN #Tmp_DuplicateMessages D
                   ON L.[message] = D.[message] AND
                      L.Entry_ID <> D.Entry_ID_First AND
                      L.Entry_ID <> D.Entry_ID_Last
            ORDER BY L.[message], L.Entry_ID
            --
	        SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            INSERT INTO #Tmp_MessagesToDelete
            SELECT L.Entry_ID
            FROM T_Log_Entries L
                 INNER JOIN #Tmp_DuplicateMessages D
                   ON L.[message] = D.[message] AND
                      L.Entry_ID <> D.Entry_ID_First
            ORDER BY L.[message], L.Entry_ID
            --
	        SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        ----------------------------------------------------
        -- Show the duplicate messages, along with an action message
        ----------------------------------------------------
        --     
        If @infoOnly = 0
        Begin
            Set @statusKeep = 'Retained'
            Set @statusDelete = 'Deleted'
        End
        Else
        Begin
            Set @statusKeep = 'Keep'
            Set @statusDelete = 'Delete'
        End
        
        SELECT L.*,
                CASE
                    WHEN D.Entry_ID IS NULL THEN @statusKeep
                    ELSE @statusDelete
                END AS Status
        FROM T_Log_Entries L
                LEFT OUTER JOIN #Tmp_MessagesToDelete D
                ON L.Entry_ID = D.Entry_ID
        WHERE L.Message IN ( SELECT [Message] FROM #Tmp_DuplicateMessages )
        ORDER BY L.[message], L.Entry_ID
        --
	    SELECT @myError = @@error, @myRowCount = @@rowcount

        If @infoOnly = 0
        Begin
            ----------------------------------------------------
            -- Remove the duplicates
            ----------------------------------------------------
            --     
            DELETE FROM T_Log_Entries
            WHERE Entry_ID IN ( SELECT Entry_ID FROM #Tmp_MessagesToDelete )
            --
	        SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @deletedMessageCount = @myRowCount

            SELECT @duplicateMessageCount = Count(*)
            FROM #Tmp_DuplicateMessages

            Set @message = 'Found ' + Cast(@duplicateMessageCount As varchar(12)) + ' duplicate ' + dbo.CheckPlural(@duplicateMessageCount, 'message', 'messages') + ' in T_Log_Entries; ' + 
                           'deleted ' +  Cast(@deletedMessageCount As varchar(12)) + dbo.CheckPlural(@myRowCount, ' log entry', ' log entries')

            Print @message

            If @duplicateMessageCount > 0 Or @deletedMessageCount > 0
            Begin
                Exec PostLogEntry 'Normal', @message, 'ConsolidateLogMessages'
            End

            If @deletedMessageCount > 0 And @changeErrorsToErrorIgnore > 0
            Begin
                UPDATE T_Log_Entries
                SET [type] = 'ErrorIgnore'
                WHERE [type] = 'Error' AND
                      Message IN ( SELECT [Message]
                                   FROM #Tmp_DuplicateMessages )
                --
	            SELECT @myError = @@error, @myRowCount = @@rowcount

            End
        End
        
    End Try
    Begin Catch
        -- Error caught; log the error
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'ConsolidateLogMessages')
        exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
                                @ErrorNum = @myError output, @message = @message output
    End Catch
    
Done:
    
    return @myError


GO
