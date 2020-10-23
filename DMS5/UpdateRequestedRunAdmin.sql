/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAdmin] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateRequestedRunAdmin]
/****************************************************
**
**  Desc: 
**      Requested run admin operations 
**      Will only update Active and Inactive requests
**
**      Example contents of @requestList:
**      <r i="545499" /><r i="545498" /><r i="545497" /><r i="545496" /><r i="545495" />
**
**      Description of the modes
**        'Active'    sets the requests to the Active state
**        'Inactive'  sets the requests to the Inactive state
**        'Delete'    deletes the requests
**        'UnassignInstrument' will change the Queue_State to 1 for requests that have a Queue_State of 2 ("Assigned"); skips any with a Queue_State of 3 ("Analyzed")
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/09/2010
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          12/12/2011 mem - Now calling AlterEventLogEntryUserMultiID
**          11/16/2016 mem - Call UpdateCachedRequestedRunEUSUsers for updated Requested runs
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Add additional debug logging
**          10/20/2020 mem - Add mode 'UnassignInstrument'
**          10/21/2020 mem - Set Queue_Instrument_ID to null when unassigning
**    
*****************************************************/
(
    @requestList text,                -- XML describing list of Requested Run IDs
    @mode varchar(32),                -- 'Active', 'Inactive', 'Delete', or 'UnassignInstrument'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
As
    SET NOCOUNT ON 

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    SET @message = ''

    Declare @UsageMessage varchar(512) = ''
    Declare @stateID int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateRequestedRunAdmin', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Declare @logMessage varchar(4096)        

    -- Set to 1 to log the contents of @requestList
    Declare @debugEnabled tinyint = 0
    
    If @debugEnabled > 0
    Begin
        Set @logMessage = Cast(@requestList as varchar(4000))        
        exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunAdmin'

        Declare @argLength Int = DataLength(@requestList)
        Set @logMessage = Cast(@argLength As Varchar(12)) + ' characters in @requestList'
        exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunAdmin'
    End
    
    -----------------------------------------------------------
    -- temp table to hold list of requests
    -----------------------------------------------------------
    --
    CREATE TABLE #TMP (
        Item VARCHAR(128),
        Status VARCHAR(32) NULL,
        Origin VARCHAR(32) NULL,
        ItemID int NULL
    )
    SET @xml = @requestList
    --
    INSERT INTO #TMP
        ( Item )
    SELECT
        xmlNode.value('@i', 'nvarchar(256)') Item
    FROM @xml.nodes('//r') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error trying to convert list'
        GOTO DoneNoLog
    End

    If @debugEnabled > 0
    Begin
        Set @logMessage = Cast(@myRowCount As Varchar(12)) + ' rows inserted into #TMP'
        exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunAdmin'
    End

    -----------------------------------------------------------
    -- Validate the request list
    -----------------------------------------------------------
    --
     UPDATE #TMP
     SET Status = RDS_Status,
         Origin = RDS_Origin
     FROM #TMP
          INNER JOIN dbo.T_Requested_Run
            ON Item = CONVERT(varchar(12), dbo.T_Requested_Run.ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error trying to get status'
        GOTO DoneNoLog
    End
    
    IF EXISTS (SELECT * FROM #TMP WHERE Status IS NULL)
    Begin
        SET @myError = 51012
        set @message = 'There were invalid request IDs'
        GOTO DoneNoLog
    End

    IF EXISTS (SELECT * FROM #TMP WHERE not Status IN ('Active', 'Inactive'))
    Begin
        SET @myError = 51013
        set @message = 'Cannot change requests that are in status other than "Active" or "Inactive"'
        GOTO DoneNoLog
    End

    IF EXISTS (SELECT * FROM #TMP WHERE Not Origin = 'user')
    Begin
        SET @myError = 51013
        set @message = 'Cannot change requests that were not entered by user'
        GOTO DoneNoLog
    End

    -----------------------------------------------------------
    -- Populate column ItemID in #TMP
    -----------------------------------------------------------
    --
    UPDATE #TMP
    SET ItemID = Try_Convert(int, Item)
    
    -----------------------------------------------------------
    -- Populate a temporary table with the list of Requested Run IDs to be updated or deleted
    -----------------------------------------------------------
    --
    CREATE TABLE #TmpIDUpdateList (
        TargetID int NOT NULL
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
    
    INSERT INTO #TmpIDUpdateList (TargetID)
    SELECT DISTINCT ItemID
    FROM #TMP
    WHERE Not ItemID Is Null
    ORDER BY ItemID

    -----------------------------------------------------------
    --  Update status
    -----------------------------------------------------------
    --
    If @mode = 'Active' OR @mode = 'Inactive'
    Begin
        UPDATE T_Requested_Run
        SET RDS_Status = @mode
        WHERE ID IN ( SELECT ItemID
                      FROM #TMP ) AND RDS_Status <> 'Completed'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error trying to update status'
            GOTO done
        End

        Set @UsageMessage = 'Updated ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.CheckPlural(@myRowCount, 'request', 'requests')

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call AlterEventLogEntryUserMultiID
            -- to alter the Entered_By field in T_Event_Log
            -- This procedure uses #TmpIDUpdateList
            --
            SELECT @stateID = State_ID
            FROM T_Requested_Run_State_Name
            WHERE (State_Name = @mode)
            
            Exec AlterEventLogEntryUserMultiID 11, @stateID, @callingUser
        End
        
        -- Call UpdateCachedRequestedRunEUSUsers for each entry in #TMP
        --
        Declare @continue tinyint = 1
        Declare @requestId int = -100000
        
        While @continue = 1
        Begin
            SELECT TOP 1 @requestId = ItemID
            FROM #TMP
            WHERE ItemID > @requestId
            ORDER BY ItemID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Exec UpdateCachedRequestedRunEUSUsers @requestId
            End
            
        End
        
        GOTO Done
    END

    -----------------------------------------------------------
    -- Delete requests
    -----------------------------------------------------------
    --
    If @mode = 'Delete'
    Begin
        DELETE FROM T_Requested_Run
        WHERE ID IN ( SELECT ItemID
                      FROM #TMP ) AND RDS_Status <> 'Completed'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error trying to delete requests'
            GOTO done
        End

        Set @UsageMessage = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.CheckPlural(@myRowCount, 'request', 'requests')

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call AlterEventLogEntryUserMultiID
            -- to alter the Entered_By field in T_Event_Log
            -- This procedure uses #TmpIDUpdateList
            --
            Set @stateID = 0
            
            Exec AlterEventLogEntryUserMultiID 11, @stateID, @callingUser
        End
        
        -- Remove any cached EUS user lists
        DELETE FROM T_Active_Requested_Run_Cached_EUS_Users
        WHERE Request_ID IN ( SELECT ItemID
                              FROM #TMP )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        GOTO Done
    END
        
    -----------------------------------------------------------
    -- Unassign requests
    -----------------------------------------------------------
    --
    If @mode = 'UnassignInstrument'
    Begin
        UPDATE T_Requested_Run
        SET Queue_State = 1, 
            Queue_Instrument_ID = Null
        WHERE ID IN ( SELECT ItemID
                      FROM #TMP ) AND 
              RDS_Status <> 'Completed' AND
              (Queue_State = 2 OR Not Queue_Instrument_ID Is NULL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error trying to unassign requests'
            GOTO done
        End

        Set @UsageMessage = 'Unassigned ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.CheckPlural(@myRowCount, 'request', 'requests') + ' from the queued instrument'

        GOTO Done
    END

Done:
    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------
    
    Exec PostUsageLogEntry 'UpdateRequestedRunAdmin', @UsageMessage

DoneNoLog:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAdmin] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAdmin] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAdmin] TO [Limited_Table_Write] AS [dbo]
GO
