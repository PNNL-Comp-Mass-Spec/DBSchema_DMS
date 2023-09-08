/****** Object:  StoredProcedure [dbo].[update_requested_run_wp] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_wp]
/****************************************************
**
**  Desc:
**      Updates the work package for requested runs
**      from an old value to a new value
**
**      If @requestIdList is empty, then finds active requested runs that use @OldWorkPackage
**
**      If @requestIdList is defined, then finds all requested runs in the list that use @OldWorkPackage
**      regardless of the state
**
**      Changes will be logged to T_Log_Entries
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/17/2020 mem - Fix typo in error message
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/19/2023 mem - Rename request ID list parameter
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
(
    @oldWorkPackage varchar(50),
    @newWorkPackage varchar(50),
    @requestIdList varchar(max) = '',     -- Optional: if blank, finds active requested runs; if defined, updates all of the specified request IDs if they use @OldWorkPackage
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @LogMessage varchar(2048)
    Declare @RequestCountToUpdate int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_wp', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

        ----------------------------------------------------------
        -- Validate the inputs
        ----------------------------------------------------------

        Set @OldWorkPackage = dbo.scrub_whitespace(@OldWorkPackage)
        Set @NewWorkPackage = dbo.scrub_whitespace(@NewWorkPackage)
        Set @requestIdList = IsNull(@requestIdList, '')
        Set @message = ''
        Set @callingUser = IsNull(@callingUser, '')
        Set @InfoOnly = IsNull(@InfoOnly, 0)

        If @CallingUser = ''
            Set @CallingUser = Suser_sname()

        If @OldWorkPackage = ''
            RAISERROR ('Old work package must be specified', 11, 16)

        If @NewWorkPackage = ''
            RAISERROR ('New work package must be specified', 11, 16)

        -- Uncomment to debug
        -- Set @LogMessage = 'Updating work package from ' + @OldWorkPackage + ' to ' + @NewWorkPackage + ' for requests: ' + @requestIdList
        -- Exec post_log_entry 'Debug', @LogMessage, 'update_requested_run_wp'

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------
        --
        CREATE TABLE #Tmp_ReqRunsToUpdate (
            ID int not null,
            RDS_Name varchar(128) not null,
            RDS_WorkPackage varchar(50) not null
        )

        CREATE CLUSTERED INDEX IX_Tmp_ReqRunsToUpdate ON #Tmp_ReqRunsToUpdate (ID)


        CREATE TABLE #Tmp_RequestedRunList (
            ID int not null
        )

        CREATE CLUSTERED INDEX IX_Tmp_RequestedRunList ON #Tmp_RequestedRunList (ID)

        ----------------------------------------------------------
        -- Find the Requested Runs to update
        ----------------------------------------------------------
        --
        If @requestIdList <> ''
        Begin

            -- Find requested runs using @requestIdList
            --
            INSERT INTO #Tmp_RequestedRunList( ID )
            SELECT Value
            FROM dbo.parse_delimited_list (@requestIdList, ',', 'update_requested_run_wp')
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            Declare @RRCount int

            SELECT @RRCount = COUNT(*)
            FROM #Tmp_RequestedRunList

            If @RRCount = 0
                RAISERROR ('User supplied Requested Run IDs was empty or did not contain integers', 11, 16)


            INSERT INTO #Tmp_ReqRunsToUpdate( ID,
                                              RDS_Name,
                                              RDS_WorkPackage )
            SELECT RR.ID,
                   RR.RDS_Name,
                   RR.RDS_WorkPackage
            FROM T_Requested_Run RR
                 INNER JOIN #Tmp_RequestedRunList Filter
                   ON RR.ID = Filter.ID
            WHERE RR.RDS_WorkPackage = @OldWorkPackage
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @RequestCountToUpdate = @myRowcount

            If @RequestCountToUpdate = 0
            Begin
                Set @message = 'None of the ' + Convert(varchar(12), @RRCount) + ' specified requested run IDs uses work package ' + @OldWorkPackage
                If @InfoOnly <> 0
                    SELECT @message AS Message

                Goto done
            End
        End
        Else
        Begin
            -- Find active requested runs that use @OldWorkPackage
            --

            INSERT INTO #Tmp_ReqRunsToUpdate( ID,
                                              RDS_Name,
                                              RDS_WorkPackage )
            SELECT ID,
                   RDS_Name,
                   RDS_WorkPackage
            FROM T_Requested_Run
            WHERE RDS_Status = 'active' AND
                  RDS_WorkPackage = @OldWorkPackage
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @RequestCountToUpdate = @myRowcount

            If @RequestCountToUpdate = 0
            Begin
                Set @message = 'Did not find any active requested runs with work package ' + @OldWorkPackage
                If @InfoOnly <> 0
                    SELECT @message AS Message

                Goto done
            End

        End

        ----------------------------------------------------------
        -- Generate log message that describes the requested runs that will be updated
        ----------------------------------------------------------
        --
        Create Table #Tmp_ValuesByCategory (
            Category varchar(512),
            Value int Not null
        )

        Create Table #Tmp_Condensed_Data (
            Category varchar(512),
            ValueList varchar(max)
        )

        INSERT INTO #Tmp_ValuesByCategory (Category, Value)
        SELECT 'RR', ID
        FROM #Tmp_ReqRunsToUpdate
        ORDER BY ID

        Exec condense_integer_list_to_ranges @debugMode=0

        If @InfoOnly = 0
            Set @LogMessage = 'Updated '
        Else
            Set @LogMessage = 'Will update '

        Set @LogMessage = @LogMessage + 'work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.check_plural(@myRowCount, 'run', 'runs')
        Set @LogMessage = @LogMessage + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage

        Declare @ValueList varchar(max)

        SELECT TOP 1 @ValueList = ValueList
        FROM #Tmp_Condensed_Data

        Set @LogMessage = @LogMessage + '; user ' + @CallingUser + '; IDs ' + IsNull(@ValueList, '??')


        If @InfoOnly <> 0
        Begin
            ----------------------------------------------------------
            -- Preview what would be updated
            ----------------------------------------------------------
            --
            SELECT @LogMessage as Log_Message

            SELECT ID,
                   RDS_Name AS Request_Name,
                   RDS_WorkPackage AS Old_Work_Package,
                   @NewWorkPackage AS New_Work_Package
            FROM #Tmp_ReqRunsToUpdate
            ORDER BY ID

            Set @message = 'Will update work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.check_plural(@myRowCount, 'run', 'runs') + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage

        End
        Else
        Begin
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------
            --

            UPDATE T_Requested_Run
            Set RDS_WorkPackage = @NewWorkPackage
            FROM T_Requested_Run Target
                INNER JOIN #Tmp_ReqRunsToUpdate src
                ON Target.ID = Src.ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Updated work package for ' + Convert(varchar(12), @myRowCount) + ' requested ' + dbo.check_plural(@myRowCount, 'run', 'runs') + ' from ' + @OldWorkPackage + ' to ' + @NewWorkPackage

            Exec post_log_entry 'Normal', @LogMessage, 'update_requested_run_wp'

        End

    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_requested_run_wp'
    End CATCH

Done:

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_wp] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_wp] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_wp] TO [DMS2_SP_User] AS [dbo]
GO
