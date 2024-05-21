/****** Object:  StoredProcedure [dbo].[update_requested_run_admin] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_admin]
/****************************************************
**
**  Desc:
**      Requested run admin operations; only updates Active and Inactive requested runs
**
**      Example contents of @requestList:
**        <r i="545499" /><r i="545498" /><r i="545497" /><r i="545496" /><r i="545495" />
**
**      Available modes:
**        'Active'    sets the requested runs to the Active state
**        'Inactive'  sets the requested runs to the Inactive state
**        'Delete'    deletes the requested runs
**        'UnassignInstrument' will change the Queue_State to 1 for requested runs that have a Queue_State of 2 ("Assigned"); skips any with a Queue_State of 3 ("Analyzed")
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/09/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          12/12/2011 mem - Now calling alter_event_log_entry_user_multi_id
**          11/16/2016 mem - Call update_cached_requested_run_eus_users for updated Requested runs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Add additional debug logging
**          10/20/2020 mem - Add mode 'UnassignInstrument'
**          10/21/2020 mem - Set Queue_Instrument_ID to null when unassigning
**          10/23/2020 mem - Allow updating 'fraction' based requested runs
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/23/2023 mem - Allow deleting requested runs of type 'auto' or 'fraction'
**          05/20/2024 mem - Call update_cached_requested_run_batch_stats when deleting requested runs
**          05/21/2024 mem - Avoid calling update_cached_requested_run_batch_stats multiple times for the same batch ID
**
*****************************************************/
(
    @requestList text,                -- XML describing list of Requested Run IDs
    @mode varchar(32),                -- 'Active', 'Inactive', 'Delete', or 'UnassignInstrument'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
AS
    SET NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    Set @message = ''

    Declare @UsageMessage varchar(512) = ''
    Declare @stateID int = 0
    Declare @continue tinyint = 1

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_admin', @raiseError = 1
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
        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_admin'

        Declare @argLength Int = DataLength(@requestList)
        Set @logMessage = Cast(@argLength As Varchar(12)) + ' characters in @requestList'
        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_admin'
    End

    -----------------------------------------------------------
    -- temp table to hold list of requests
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Requests (
        Item varchar(128),          -- Requested run ID, as text
        Status varchar(32) NULL,
        Origin varchar(32) NULL,
        Request_ID int NULL
    )

    Set @xml = @requestList

    INSERT INTO #Tmp_Requests ( Item )
    SELECT
        xmlNode.value('@i', 'nvarchar(256)') Item
    FROM @xml.nodes('//r') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to convert list'
        Goto DoneNoLog
    End

    If @debugEnabled > 0
    Begin
        Set @logMessage = Cast(@myRowCount As Varchar(12)) + ' rows inserted into #Tmp_Requests'
        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_admin'
    End

    -----------------------------------------------------------
    -- Validate the request list
    -----------------------------------------------------------

     UPDATE #Tmp_Requests
     SET Status = RDS_Status,
         Origin = RDS_Origin
     FROM #Tmp_Requests
          INNER JOIN dbo.T_Requested_Run
            ON Item = CONVERT(varchar(12), dbo.T_Requested_Run.ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to get status'
        Goto DoneNoLog
    End

    If Exists (SELECT * FROM #Tmp_Requests WHERE Status IS NULL)
    Begin
        Set @myError = 51012
        Set @message = 'There were invalid request IDs'
        Goto DoneNoLog
    End

    If Exists (SELECT * FROM #Tmp_Requests WHERE not Status IN ('Active', 'Inactive'))
    Begin
        Set @myError = 51013
        Set @message = 'Cannot change requests that are in status other than "Active" or "Inactive"'
        Goto DoneNoLog
    End

    If Exists (SELECT * FROM #Tmp_Requests WHERE Not Origin In ('user', 'fraction') And @mode <> 'Delete')
    Begin
        Set @myError = 51013
        Set @message = 'Cannot change requests that were not entered by user'
        Goto DoneNoLog
    End

    -----------------------------------------------------------
    -- Populate column Request_ID in #Tmp_Requests
    -----------------------------------------------------------

    UPDATE #Tmp_Requests
    SET Request_ID = Try_Parse(Item as int)

    -----------------------------------------------------------
    -- Populate a temporary table with the list of Requested Run IDs to be updated or deleted
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Request_IDs_Update_List (
        TargetID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #Tmp_Request_IDs_Update_List (TargetID)

    INSERT INTO #Tmp_Request_IDs_Update_List (TargetID)
    SELECT DISTINCT Request_ID
    FROM #Tmp_Requests
    WHERE Not Request_ID Is Null
    ORDER BY Request_ID

    If @mode = 'Active' OR @mode = 'Inactive'
    Begin
        -----------------------------------------------------------
        -- Update status
        -----------------------------------------------------------

        UPDATE T_Requested_Run
        SET RDS_Status = @mode
        WHERE ID IN (SELECT Request_ID FROM #Tmp_Requests) AND
              RDS_Status <> 'Completed'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error trying to update status'
            Goto Done
        End

        Set @UsageMessage = 'Updated ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.check_plural(@myRowCount, 'request', 'requests')

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call alter_event_log_entry_user_multi_id to alter the Entered_By field in T_Event_Log
            -- That procedure uses #Tmp_Request_IDs_Update_List

            SELECT @stateID = State_ID
            FROM T_Requested_Run_State_Name
            WHERE State_Name = @mode

            Exec alter_event_log_entry_user_multi_id 11, @stateID, @callingUser
        End

        ---------------------------------------------------
        -- Call update_cached_requested_run_eus_users for each entry in #Tmp_Requests
        ---------------------------------------------------

        Declare @requestId int = -100000
        Set @continue = 1

        While @continue = 1
        Begin
            SELECT TOP 1 @requestId = Request_ID
            FROM #Tmp_Requests
            WHERE Request_ID > @requestId
            ORDER BY Request_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Exec update_cached_requested_run_eus_users @requestId
            End

        End

        Goto Done
    End

    If @mode = 'Delete'
    Begin
        -----------------------------------------------------------
        -- Delete requested runs
        -----------------------------------------------------------

        CREATE TABLE #Tmp_Batch_IDs (
            Batch_ID int NOT NULL
        )

        INSERT INTO #Tmp_Batch_IDs (Batch_ID)
        SELECT DISTINCT RDS_BatchID
        FROM T_Requested_Run
        WHERE ID IN (SELECT Request_ID FROM #Tmp_Requests) AND
              RDS_Status <> 'Completed'

        DELETE FROM T_Requested_Run
        WHERE ID IN (SELECT Request_ID FROM #Tmp_Requests) AND
              RDS_Status <> 'Completed'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error trying to delete requests'
            Goto Done
        End

        Set @UsageMessage = 'Deleted ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.check_plural(@myRowCount, 'request', 'requests')

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call alter_event_log_entry_user_multi_id to alter the Entered_By field in T_Event_Log
            -- That procedure uses #Tmp_Request_IDs_Update_List

            Set @stateID = 0

            Exec alter_event_log_entry_user_multi_id 11, @stateID, @callingUser
        End

        -- Remove any cached EUS user lists
        DELETE FROM T_Active_Requested_Run_Cached_EUS_Users
        WHERE Request_ID IN (SELECT Request_ID
                             FROM #Tmp_Requests)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -----------------------------------------------------------
        -- Update batches associated with the deleted requested runs
        -- (skipping Batch_ID 0)
        -----------------------------------------------------------

        Declare @batchID int = -1
        Set @continue = 1

        While @continue > 0
        Begin
            SELECT TOP 1 @batchID = Batch_ID
            FROM #Tmp_Batch_IDs
            WHERE Batch_ID > @batchID
            ORDER BY Batch_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Exec update_cached_requested_run_batch_stats @batchID = @batchID
            End
        End

        Goto Done
    End

    -----------------------------------------------------------
    -- Unassign requests
    -----------------------------------------------------------

    If @mode = 'UnassignInstrument'
    Begin
        UPDATE T_Requested_Run
        SET Queue_State = 1,
            Queue_Instrument_ID = Null
        WHERE ID IN (SELECT Request_ID FROM #Tmp_Requests) AND
              RDS_Status <> 'Completed' AND
              (Queue_State = 2 OR NOT Queue_Instrument_ID Is NULL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error trying to unassign requests'
            Goto Done
        End

        Set @UsageMessage = 'Unassigned ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.check_plural(@myRowCount, 'request', 'requests') + ' from the queued instrument'

        Goto Done
    End

Done:
    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Exec post_usage_log_entry 'update_requested_run_admin', @UsageMessage

DoneNoLog:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_admin] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_admin] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_admin] TO [Limited_Table_Write] AS [dbo]
GO
