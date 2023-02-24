/****** Object:  StoredProcedure [dbo].[update_cached_requested_run_eus_users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_requested_run_eus_users]
/****************************************************
**
**  Desc:   Updates the data in T_Active_Requested_Run_Cached_EUS_Users
**          This table tracks the list of EUS users for each active requested run
**
**          We only track active requested runs because V_Requested_Run_Active_Export
**          only returns active requested runs, and that view is the primary
**          beneficiary of T_Active_Requested_Run_Cached_EUS_Users
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/16/2016 mem - Initial Version
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/21/2016 mem - Do not use a Merge statement when @RequestID is non-zero
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int = 0,                 -- Specific Request to update, or 0 to update all active Requested Runs
    @message varchar(255) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    Set @RequestID = IsNull(@RequestID, 0)
    set @message = ''

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try

        If @RequestID <> 0
        Begin
            -- Updating a specific requested run
            If Exists (SELECT * FROM T_Requested_Run WHERE RDS_Status = 'Active' AND ID = @RequestID)
            Begin
                -- Updating a single requested run; to avoid commit conflicts, do not use a merge statement
                If Exists (SELECT * FROM T_Active_Requested_Run_Cached_EUS_Users WHERE Request_ID = @RequestID)
                Begin
                    UPDATE T_Active_Requested_Run_Cached_EUS_Users
                    Set User_List = dbo.get_requested_run_eus_users_list(@RequestID, 'V')
                    WHERE Request_ID = @RequestID
                End
                Else
                Begin
                    INSERT INTO T_Active_Requested_Run_Cached_EUS_Users (Request_ID, User_List)
                    Values (@RequestID, dbo.get_requested_run_eus_users_list(@RequestID, 'V'))
                End
            End
            Else
            Begin
                -- The request is not active; assure there is no cached entry
                If Exists (SELECT * FROM T_Active_Requested_Run_Cached_EUS_Users WHERE Request_ID = @RequestID)
                Begin
                    DELETE T_Active_Requested_Run_Cached_EUS_Users
                    WHERE Request_ID = @RequestID
                End

            End

            Goto Done
        End

        -- Updating all active requested runs
        -- or updating a single, active requested run

        set ansi_warnings off

        MERGE T_Active_Requested_Run_Cached_EUS_Users AS t
        USING (SELECT ID AS Request_ID,
                    dbo.get_requested_run_eus_users_list(ID, 'V') AS User_List
            FROM T_Requested_Run
            WHERE RDS_Status = 'Active' AND (@RequestID = 0 OR ID = @RequestID)
        ) AS s
        ON ( t.Request_ID = s.Request_ID)
        WHEN MATCHED AND (
            ISNULL( NULLIF(t.User_List, s.User_List),
                    NULLIF(s.User_List, t.User_List)) IS NOT NULL
            )
        THEN UPDATE SET
            User_List = s.User_List
        WHEN NOT MATCHED BY TARGET THEN
            INSERT(Request_ID, User_List)
            VALUES(s.Request_ID, s.User_List)
        WHEN NOT MATCHED BY SOURCE AND @RequestID = 0 THEN DELETE;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        set ansi_warnings on

        If @myError <> 0
        begin
            set @message = 'Error updating T_Active_Requested_Run_Cached_EUS_Users via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'update_cached_requested_run_eus_users'
            goto Done
        end

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_cached_requested_run_eus_users')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output

        exec post_log_entry 'Error', @message, 'update_cached_requested_run_eus_users'

        Goto Done
    End Catch

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cached_requested_run_eus_users] TO [DDL_Viewer] AS [dbo]
GO
