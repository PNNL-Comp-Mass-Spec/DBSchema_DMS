/****** Object:  StoredProcedure [dbo].[update_requested_run_batch_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_batch_parameters]
/****************************************************
**
**  Desc:
**      Change run blocking parameters given by lists
**
**      Example XML for @blockingList
**        <r i="481295" t="Run_Order" v="1" />
**        <r i="481295" t="Block" v="2" />
**        <r i="481296" t="Run_Order" v="1" />
**        <r i="481296" t="Block" v="1" />
**        <r i="481297" t="Run_Order" v="2" />
**        <r i="481297" t="Block" v="1" />
**
**      Valid values for type (t) are:
**        'BK', 'RO', 'Block', 'Run Order', 'Status', 'Instrument', or 'Cart'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/09/2010
**          02/16/2010 grk - eliminated batchID from arg list
**          09/02/2011 mem - Now calling post_usage_log_entry
**          12/15/2011 mem - Now updating @callingUser to SUSER_SNAME() if empty
**          03/28/2013 grk - added handling for cart, instrument
**          11/07/2016 mem - Add optional logging via post_log_entry
**          11/08/2016 mem - Use get_user_login_without_domain to obtain the user's network login
**          11/10/2016 mem - Pass '' to get_user_login_without_domain
**          11/16/2016 mem - Call update_cached_requested_run_eus_users for updated Requested runs
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/04/2019 mem - Update Last_Ordered if the run order changes
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          02/11/2023 mem - Update the usage message sent to post_usage_log_entry
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @blockingList text,             -- XML (see above)
    @mode varchar(32),              -- 'update'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
AS
    SET NOCOUNT ON

    Declare @myError INT = 0
    Declare @myRowCount INT = 0

    Declare @xml AS XML
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_requested_run_batch_parameters', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @message = ''

    If IsNull(@callingUser, '') = ''
        Set @callingUser = dbo.get_user_login_without_domain('')

    -- Set to 1 to log the contents of @blockingList
    Declare @debugEnabled tinyint = 0
    Declare @logMessage varchar(4096)

    If @debugEnabled > 0
    Begin
        Set @logMessage = Cast(@blockingList as varchar(4000))

        exec post_log_entry 'Debug', @logMessage, 'update_requested_run_batch_parameters'
    End


    -----------------------------------------------------------
    -----------------------------------------------------------
    BEGIN TRY
        -----------------------------------------------------------
        -- temp table to hold new parameters
        -----------------------------------------------------------
        --
        CREATE TABLE #Tmp_NewBatchParams (
            Parameter VARCHAR(32),
            Request INT,
            Value VARCHAR(128),
            ExistingValue VARCHAR(128) NULL
        )

        IF @mode = 'update' OR @mode = 'debug'
        BEGIN --<a>
            -----------------------------------------------------------
            -- Populate temp table with new parameters
            -----------------------------------------------------------
            --
            Set @xml = @blockingList
            --
            INSERT INTO #Tmp_NewBatchParams
                ( Parameter, Request, Value )
            SELECT
                xmlNode.value('@t', 'nvarchar(256)') Parameter,     -- Valid values are 'BK', 'RO', 'Block', 'Run Order', 'Status', 'Instrument', or 'Cart'
                xmlNode.value('@i', 'nvarchar(256)') Request,       -- Request ID
                xmlNode.value('@v', 'nvarchar(256)') Value
            FROM @xml.nodes('//r') AS R(xmlNode)

            -----------------------------------------------------------
            -- Normalize parameter names
            -----------------------------------------------------------
            --
            UPDATE #Tmp_NewBatchParams SET Parameter = 'Block' WHERE Parameter = 'BK'
            UPDATE #Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter ='RO'
            UPDATE #Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter ='Run_Order'

            IF @mode = 'debug'
            BEGIN
                SELECT * FROM #Tmp_NewBatchParams
            END

            -----------------------------------------------------------
            -- Add current values for parameters to temp table
            -----------------------------------------------------------
            --
            UPDATE #Tmp_NewBatchParams
            SET ExistingValue = CASE
                                WHEN #Tmp_NewBatchParams.Parameter = 'Block' THEN CONVERT(VARCHAR(128), RDS_Block)
                                WHEN #Tmp_NewBatchParams.Parameter = 'Run Order' THEN CONVERT(VARCHAR(128), RDS_Run_Order)
                                WHEN #Tmp_NewBatchParams.Parameter = 'Status' THEN CONVERT(VARCHAR(128), RDS_Status)
                                WHEN #Tmp_NewBatchParams.Parameter = 'Instrument' THEN RDS_instrument_group
                                ELSE ''
                                END
            FROM #Tmp_NewBatchParams
                 INNER JOIN T_Requested_Run
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID

            -- LC cart (requires a join)
            UPDATE #Tmp_NewBatchParams
            SET ExistingValue = dbo.T_LC_Cart.Cart_Name
            FROM #Tmp_NewBatchParams
                 INNER JOIN T_Requested_Run
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
                 INNER JOIN T_LC_Cart
                   ON T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID
            WHERE #Tmp_NewBatchParams.Parameter = 'Cart'


            IF @mode = 'debug'
            BEGIN
                SELECT * FROM #Tmp_NewBatchParams
            END

            -----------------------------------------------------------
            -- Remove entries that are unchanged
            -----------------------------------------------------------
            --
            DELETE FROM #Tmp_NewBatchParams WHERE (#Tmp_NewBatchParams.Value = #Tmp_NewBatchParams.ExistingValue)


            -----------------------------------------------------------
            -- Validate
            -----------------------------------------------------------

            Declare @misnamedCarts VARCHAR(4096) = ''
            SELECT @misnamedCarts = @misnamedCarts + #Tmp_NewBatchParams.Value + ', '
            FROM #Tmp_NewBatchParams
            WHERE #Tmp_NewBatchParams.Parameter = 'Cart' AND
                  NOT (#Tmp_NewBatchParams.Value IN ( SELECT Cart_Name
                                       FROM dbo.T_LC_Cart ))
            --
            IF @misnamedCarts != ''
                RAISERROR ('Cart(s) %s are incorrect', 11, 20, @misnamedCarts)

        END --<a>

        IF @mode = 'debug'
        BEGIN
            SELECT * FROM #Tmp_NewBatchParams
        END

        -----------------------------------------------------------
        -- Is there anything left to update?
        -----------------------------------------------------------
        --
        IF NOT EXISTS (SELECT * FROM #Tmp_NewBatchParams)
        BEGIN
            Set @message = 'No run parameters to update'
            RETURN 0
        END

        -----------------------------------------------------------
        -- Actually do the update
        -----------------------------------------------------------
        --
        IF @mode = 'update'
        BEGIN --<c>
            Declare @transName VARCHAR(32) = 'update_requested_run_batch_parameters'

            BEGIN TRANSACTION @transName

            UPDATE T_Requested_Run
            SET RDS_Block = #Tmp_NewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #Tmp_NewBatchParams
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #Tmp_NewBatchParams.Parameter = 'Block'

            UPDATE T_Requested_Run
            SET RDS_Run_Order = #Tmp_NewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #Tmp_NewBatchParams
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #Tmp_NewBatchParams.Parameter = 'Run Order'

            UPDATE T_Requested_Run
            SET RDS_Status = #Tmp_NewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #Tmp_NewBatchParams
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #Tmp_NewBatchParams.Parameter = 'Status'

            UPDATE T_Requested_Run
            SET RDS_Cart_ID = dbo.T_LC_Cart.ID
            FROM T_Requested_Run
                 INNER JOIN #Tmp_NewBatchParams
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
                 INNER JOIN dbo.T_LC_Cart
                   ON #Tmp_NewBatchParams.Value = dbo.T_LC_Cart.Cart_Name
            WHERE #Tmp_NewBatchParams.Parameter = 'Cart'

            UPDATE T_Requested_Run
            SET RDS_instrument_group = #Tmp_NewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #Tmp_NewBatchParams
                   ON #Tmp_NewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #Tmp_NewBatchParams.Parameter = 'Instrument'

            COMMIT TRANSACTION @transName

            If Exists (SELECT * FROM #Tmp_NewBatchParams WHERE Parameter = 'Run Order')
            Begin
                -- If all of the updated requests come from the same batch,
                -- update Last_Ordered in T_Requested_Run_Batches

                Declare @minBatchID Int = 0
                Declare @maxBatchID int = 0

                SELECT @minBatchID = Min(RDS_BatchID),
                       @maxBatchID = Max(RDS_BatchID)
                FROM #Tmp_NewBatchParams Src
                     INNER JOIN T_Requested_Run RR
                       ON Src.Request = RR.ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If (@minBatchID > 0 Or @maxBatchID > 0)
                Begin
                    If @minBatchID = @maxBatchID
                    Begin
                        UPDATE T_Requested_Run_Batches
                        SET Last_Ordered = GetDate()
                        WHERE ID = @minBatchID
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount
                    End
                    Else
                    Begin
                        Declare @requestedRunList Varchar(1024) = null

                        SELECT @requestedRunList = Coalesce(@requestedRunList + ', ' + Cast(Request AS varchar(12)),
                                                            Cast(Request AS varchar(12)))
                        FROM #Tmp_NewBatchParams
                        ORDER BY Request

                        Set @logMessage = 'Requested runs do not all belong to the same batch:  ' +
                                          Cast(@minBatchID As varchar(12)) + ' vs. ' + Cast(@maxBatchID As varchar(12)) +
                                          '; see requested runs ' + @requestedRunList

                        exec post_log_entry 'Warning', @logMessage, 'update_requested_run_batch_parameters'
                    End
                End
            End

            If Exists (SELECT * FROM #Tmp_NewBatchParams WHERE Parameter = 'Status')
            Begin
                -- Call update_cached_requested_run_eus_users for each entry in #Tmp_NewBatchParams
                --
                Declare @continue tinyint = 1
                Declare @requestId int = -100000

                While @continue = 1
                Begin
                    SELECT TOP 1 @requestId = Request
                    FROM #Tmp_NewBatchParams
                    WHERE Request > @requestId AND Parameter = 'Status'
                    ORDER BY Request
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
            End

            -----------------------------------------------------------
            -- convert changed items to XML for logging
            -----------------------------------------------------------
            --
            Declare @changeSummary VARCHAR(max) = ''
            --
            SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), Request) + '" t="' + Parameter + '" v="' + Value + '" />'
            FROM #Tmp_NewBatchParams

            -----------------------------------------------------------
            -- log changes
            -----------------------------------------------------------
            --
            IF @changeSummary <> ''
            BEGIN
                INSERT INTO T_Factor_Log
                    (changed_by, changes)
                VALUES
                    (@callingUser, @changeSummary)
            END

            ---------------------------------------------------
            -- Log SP usage
            ---------------------------------------------------

            Declare @UsageMessage VARCHAR(512) = ''
            Declare @requestIdFirst int
            Declare @requestIdLast int

            SELECT @requestIdFirst = MIN(Request),
                   @requestIdLast  = MAX(Request)
            FROM #Tmp_NewBatchParams

            If @requestIdFirst Is Null
            Begin
                Set @UsageMessage = 'Request IDs: not defined'
            End
            Else
            Begin
                If @requestIdFirst = @requestIdLast
                    Set @UsageMessage = 'Request ID: ' + Convert(varchar(12), @requestIdFirst)
                Else
                    Set @UsageMessage = 'Request IDs: ' + Convert(varchar(12), @requestIdFirst) + ' - ' + Convert(varchar(12), @requestIdLast)
            End

            EXEC post_usage_log_entry 'update_requested_run_batch_parameters', @UsageMessage
        END --<c>

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message OUTPUT, @myError OUTPUT

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_requested_run_batch_parameters'
    END CATCH
    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_batch_parameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_requested_run_batch_parameters] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_batch_parameters] TO [Limited_Table_Write] AS [dbo]
GO
