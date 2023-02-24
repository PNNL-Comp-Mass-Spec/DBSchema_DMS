/****** Object:  StoredProcedure [dbo].[update_run_op_log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_run_op_log]
/****************************************************
**
**  Desc:   Update selected items from instrument run
**          tracking-related entities
**
**          @changes tracks the updates to be applied, in XML format
**          Example contents of @changes
**          <run request="206498" usage="USER" proposal="123456" user="1001" />
**          <interval id="268646" note="On hold pending scheduling,Broken[50%],CapDev[25%],StaffNotAvailable[25%],Operator[40677]" />
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/21/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Pass @invalidUsage to add_update_run_interval; continue updating long intervals if the usage info fails validation for a given entry
**          06/12/2018 mem - Send @maxLength to append_to_text
**          05/24/2022 mem - Do not call post_log_entry for errors of the form "Total percentage (0) does not add up to 100 for ID 1017648"
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @changes text, -- see formating note above
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, NOCOUNT ON
    Set CONCAT_NULL_YIELDS_NULL ON
    Set ANSI_PADDING ON

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Set @message = ''

    Declare @logErrors tinyint = 1

    Declare @xml XML = CONVERT(XML, @changes)

    Declare @prevID INT = 0
    Declare @curID INT = 0
    Declare @done INT = 0
    Declare @msg VARCHAR(512)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_run_op_log', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        -----------------------------------------------------------
        -- Make temp table to hold requested run changes
        -- and populate it from the input XML
        -----------------------------------------------------------
        --
        CREATE TABLE #RRCHG (
            request int NULL,
            usage NVARCHAR(256) NULL,
            proposal NVARCHAR(256) NULL,
            [emsl_user] NVARCHAR(2048) NULL,
            statusID INT null
        )

        INSERT INTO #RRCHG
            (request, usage,  proposal,emsl_user)
        SELECT
            xmlNode.value('@request', 'nvarchar(256)') request,
            xmlNode.value('@usage', 'nvarchar(256)') usage,
            xmlNode.value('@proposal', 'nvarchar(256)') proposal,
            xmlNode.value('@user', 'nvarchar(256)') emsl_user
        FROM @xml.nodes('//run') AS R(xmlNode)

        -- Get current status of request (needed for change log updating)
        --
        UPDATE #RRCHG
        Set statusID = TRSN.State_ID
        FROM #RRCHG
             INNER JOIN T_Requested_Run TRR
               ON #RRCHG.request = TRR.ID
             INNER JOIN T_Requested_Run_State_Name TRSN
               ON TRR.RDS_Status = TRSN.State_Name

        ---------------------------------------------------
        -- Create temp table to hold interval changes
        -- and populate it from the input XML
        ---------------------------------------------------

        CREATE TABLE #INTCHG (
            id int,
            note NVARCHAR(2048)
        )

        INSERT INTO #INTCHG
            (id, note)
        SELECT
            xmlNode.value('@id', 'nvarchar(256)') request,
            xmlNode.value('@note', 'nvarchar(2048)') note
        FROM @xml.nodes('//interval') AS R(xmlNode)

        -----------------------------------------------------------
        -- Loop through requested run changes
        -- and validate and update
        -----------------------------------------------------------
        Declare
            @AutoPopulateUserListIfBlank tinyint = 1,
            @eusUsageTypeID INT,
            @eusUsageType varchar(50),
            @eusProposalID varchar(10),
            @eusUsersList varchar(1024),
            @StatusID int

        Set @prevID = 0
        Set @curID = 0
        Set @done = 0
        WHILE @done = 0
        BEGIN --<a>
            Set @curID = 0
            SELECT TOP 1
                @curID = request,
                @prevID = request,
                @eusUsageType = usage,
                @eusProposalID = proposal,
                @eusUsersList = emsl_user,
                @StatusID = statusID
            FROM #RRCHG
            WHERE request > @prevID
            ORDER BY request

            IF @curID = 0
            BEGIN
                Set @done = 1
            END
            ELSE
            BEGIN --<c>
                exec @myError = validate_eus_usage
                            @eusUsageType output,
                            @eusProposalID output,
                            @eusUsersList output,
                            @eusUsageTypeID output,
                            @msg output,
                            @AutoPopulateUserListIfBlank

                If @myError <> 0
                Begin
                    RAISERROR ('validate_eus_usage: %s', 11, 1, @msg)
                End

                -----------------------------------------------------------
                -- Update the requested run
                -----------------------------------------------------------

                UPDATE T_Requested_Run
                Set
                    RDS_EUS_Proposal_ID = @eusProposalID,
                    RDS_EUS_UsageType = @eusUsageTypeID
                WHERE (ID = @curID)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                if @myError <> 0
                    RAISERROR ('Update operation failed: "%s"', 11, 4, @curID)

                -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
                If Len(@callingUser) > 0
                Begin
                    Exec alter_event_log_entry_user 11, @curID, @StatusID, @callingUser
                End

                -- Assign users to the request
                --
                exec @myError = assign_eus_users_to_requested_run
                                        @curID,
                                        @eusProposalID,
                                        @eusUsersList,
                                        @msg output
                if @myError <> 0
                Begin
                    RAISERROR ('assign_eus_users_to_requested_run: %s', 11, 20, @msg)
                End
            END --<c>
        END --<a>

        ---------------------------------------------------
        -- Loop though long intervals and update
        ---------------------------------------------------
        --
        Declare @comment varchar(MAX)
        Declare @invalidUsage tinyint = 0
        Declare @invalidEntries int = 0

        Set @prevID = 0
        Set @curID = 0
        Set @done = 0
        WHILE @done = 0
        BEGIN --<x>
            Set @curID = 0
            SELECT TOP 1
                @curID = id,
                @prevID = id,
                @comment = note
            FROM #INTCHG
            WHERE id > @prevID
            ORDER BY id

            IF @curID = 0
            BEGIN
                Set @done = 1
            END
            ELSE
            BEGIN --<y>

                exec @myError = add_update_run_interval
                                            @curID,
                                            @comment,
                                            'update',
                                            @msg output,
                                            @callingUser,
                                            @showDebug=0,
                                            @invalidUsage=@invalidUsage output

                If @invalidUsage > 0
                Begin
                    -- Update @message then continue to the next item
                    Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 512)
                    Set @myError = 0
                    Set @invalidEntries = @invalidEntries + 1
                End
                Else If @myError <> 0
                Begin
                    RAISERROR ('add_update_run_interval: %s', 11, 20, @msg)
                End

            END --<y>
        END --<x>

        If @invalidEntries > 0
        Begin
            If @message Like '%Total percentage%'
            Begin
                Set @logErrors = 0
            End

            -- @msg will be 'Parse error: error details' or 'Parse errors: error details'
            Set @msg = 'Parse ' + dbo.check_plural(@invalidEntries, 'error', 'errors') + ': ' + @message
            RAISERROR (@msg, 11, 21)
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'update_run_op_log'
        End
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_run_op_log] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_run_op_log] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_run_op_log] TO [DMS2_SP_User] AS [dbo]
GO
