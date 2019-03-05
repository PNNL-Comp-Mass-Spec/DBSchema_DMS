/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBatchParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateRequestedRunBatchParameters]
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
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          12/15/2011 mem - Now updating @callingUser to SUSER_SNAME() if empty
**          03/28/2013 grk - added handling for cart, instrument
**          11/07/2016 mem - Add optional logging via PostLogEntry
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          11/16/2016 mem - Call UpdateCachedRequestedRunEUSUsers for updated Requested runs
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
    @blockingList text,             -- XML (see above)
    @mode varchar(32),              -- 'update'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
As
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
    Exec @authorized = VerifySPAuthorized 'UpdateRequestedRunBatchParameters', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    
    Set @message = ''

    If IsNull(@callingUser, '') = ''
        Set @callingUser = dbo.GetUserLoginWithoutDomain('')
        
    Declare @batchID int = 0

    -- Set to 1 to log the contents of @blockingList
    Declare @debugEnabled tinyint = 0
    Declare @logMessage varchar(4096)        
    
    If @debugEnabled > 0
    Begin
        Set @logMessage = Cast(@blockingList as varchar(4000))
        
        exec PostLogEntry 'Debug', @logMessage, 'UpdateRequestedRunBatchParameters'
    End
    
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    BEGIN TRY 
        -----------------------------------------------------------
        -- temp table to hold new parameters
        -----------------------------------------------------------
        --
        CREATE TABLE #TmpNewBatchParams (
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
            INSERT INTO #TmpNewBatchParams
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
            UPDATE #TmpNewBatchParams SET Parameter = 'Block' WHERE Parameter = 'BK'
            UPDATE #TmpNewBatchParams SET Parameter = 'Run Order' WHERE Parameter ='RO'
            UPDATE #TmpNewBatchParams SET Parameter = 'Run Order' WHERE Parameter ='Run_Order'

            IF @mode = 'debug'
            BEGIN 
                SELECT * FROM #TmpNewBatchParams
            END 

            -----------------------------------------------------------
            -- Add current values for parameters to temp table
            -----------------------------------------------------------
            --
            UPDATE #TmpNewBatchParams
            SET ExistingValue = CASE 
                                WHEN #TmpNewBatchParams.Parameter = 'Block' THEN CONVERT(VARCHAR(128), RDS_Block)
                                WHEN #TmpNewBatchParams.Parameter = 'Run Order' THEN CONVERT(VARCHAR(128), RDS_Run_Order)
                                WHEN #TmpNewBatchParams.Parameter = 'Status' THEN CONVERT(VARCHAR(128), RDS_Status)
                                WHEN #TmpNewBatchParams.Parameter = 'Instrument' THEN RDS_instrument_name
                                ELSE ''
                                END 
            FROM #TmpNewBatchParams
                 INNER JOIN T_Requested_Run
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID

            -- LC cart (requires a join)
            UPDATE #TmpNewBatchParams
            SET ExistingValue = dbo.T_LC_Cart.Cart_Name
            FROM #TmpNewBatchParams
                 INNER JOIN T_Requested_Run
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
                 INNER JOIN T_LC_Cart
                   ON T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID
            WHERE #TmpNewBatchParams.Parameter = 'Cart'


            IF @mode = 'debug'
            BEGIN 
                SELECT * FROM #TmpNewBatchParams
            END 

            -----------------------------------------------------------
            -- Remove entries that are unchanged
            -----------------------------------------------------------
            --
            DELETE FROM #TmpNewBatchParams WHERE (#TmpNewBatchParams.Value = #TmpNewBatchParams.ExistingValue)


            -----------------------------------------------------------
            -- Validate
            -----------------------------------------------------------

            Declare @misnamedCarts VARCHAR(4096) = ''
            SELECT @misnamedCarts = @misnamedCarts + #TmpNewBatchParams.Value + ', '
            FROM #TmpNewBatchParams
            WHERE #TmpNewBatchParams.Parameter = 'Cart' AND
                  NOT (#TmpNewBatchParams.Value IN ( SELECT Cart_Name
                                       FROM dbo.T_LC_Cart ))
            --
            IF @misnamedCarts != ''
                RAISERROR ('Cart(s) %s are incorrect', 11, 20, @misnamedCarts)

        END --<a>

        IF @mode = 'debug'
        BEGIN 
            SELECT * FROM #TmpNewBatchParams
        END 
        
        -----------------------------------------------------------
        -- Is there anything left to update?
        -----------------------------------------------------------
        --
        IF NOT EXISTS (SELECT * FROM #TmpNewBatchParams)
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
            Declare @transName VARCHAR(32)
            Set @transName = 'UpdateRequestedRunBatchParameters'
            BEGIN TRANSACTION @transName

            UPDATE T_Requested_Run
            SET RDS_Block = #TmpNewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #TmpNewBatchParams
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #TmpNewBatchParams.Parameter = 'Block'
            
            UPDATE T_Requested_Run
            SET RDS_Run_Order = #TmpNewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #TmpNewBatchParams
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #TmpNewBatchParams.Parameter = 'Run Order'

            UPDATE T_Requested_Run
            SET RDS_Status = #TmpNewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #TmpNewBatchParams
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #TmpNewBatchParams.Parameter = 'Status'

            UPDATE T_Requested_Run
            SET RDS_Cart_ID = dbo.T_LC_Cart.ID
            FROM T_Requested_Run
                 INNER JOIN #TmpNewBatchParams
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
                 INNER JOIN dbo.T_LC_Cart
                   ON #TmpNewBatchParams.Value = dbo.T_LC_Cart.Cart_Name
            WHERE #TmpNewBatchParams.Parameter = 'Cart'

            UPDATE T_Requested_Run
            SET RDS_instrument_name = #TmpNewBatchParams.Value
            FROM T_Requested_Run
                 INNER JOIN #TmpNewBatchParams
                   ON #TmpNewBatchParams.Request = dbo.T_Requested_Run.ID
            WHERE #TmpNewBatchParams.Parameter = 'Instrument'

            COMMIT TRANSACTION @transName

            Begin

            If Exists (SELECT * FROM #TmpNewBatchParams WHERE Parameter = 'Status')
            Begin
                -- Call UpdateCachedRequestedRunEUSUsers for each entry in #TmpNewBatchParams
                --
                Declare @continue tinyint = 1
                Declare @requestId int = -100000
                
                While @continue = 1
                Begin
                    SELECT TOP 1 @requestId = Request
                    FROM #TmpNewBatchParams
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
                        Exec UpdateCachedRequestedRunEUSUsers @requestId
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
            FROM #TmpNewBatchParams
            
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
            Set @UsageMessage = 'Batch: ' + Convert(varchar(12), @batchID)
            EXEC PostUsageLogEntry 'UpdateRequestedRunBatchParameters', @UsageMessage
        END --<c>

    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT                           
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        Exec PostLogEntry 'Error', @message, 'UpdateRequestedRunBatchParameters'
    END CATCH
    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchParameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBatchParameters] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchParameters] TO [Limited_Table_Write] AS [dbo]
GO
