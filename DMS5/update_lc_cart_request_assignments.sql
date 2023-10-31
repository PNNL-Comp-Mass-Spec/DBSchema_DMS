/****** Object:  StoredProcedure [dbo].[update_lc_cart_request_assignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_lc_cart_request_assignments]
/****************************************************
**
**  Desc:
**  Set LC cart and col assignments for requested runs
**
**  Example XML for @cartAssignmentList
**      <r rq="543451" ct="Andromeda" co="1" cg="" />
**      <r rq="543450" ct="Andromeda" co="2" cg="" />
**      <r rq="543449" ct="Andromeda" co="1" cg="Tiger_Jup_2D_Peptides_20uL" />
**
**  Where rq is the request ID, ct is the cart name, co is the column ID, and cg is the cart config name
**  See method saveChangesToDatabase below lc_cart_request_loading in file javascript/lcmd.js
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/10/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          02/27/2017 mem - Add support for cart config name
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @cartAssignmentList text,       -- XML (see above)
    @mode varchar(32),              -- Unused, but likely 'update'
    @message varchar(512) output
)
AS
    Set NOCOUNT ON
    Set CONCAT_NULL_YIELDS_NULL ON
    Set ANSI_PADDING ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_lc_cart_request_assignments', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    Declare @xml AS xml
    Set @xml = @cartAssignmentList

    Set @message = ''

    -- Change this to 1 to enable debugging
    Declare @debugMode tinyint = 0
    Declare @debugMsg varchar(4096)

    If @debugMode > 0
    Begin
        Set @debugMsg = Cast(@cartAssignmentList As varchar(4096))
        exec post_log_entry 'Debug', @debugMsg, 'update_lc_cart_request_assignments'
    End

    -----------------------------------------------------------
    -- Create and populate temp table with block assignments
    -----------------------------------------------------------
    --
    CREATE TABLE #TMP (
        request INT,
        cart VARCHAR(64),
        cartConfig varchar(128),
        col VARCHAR(12),
        cartID INT NULL,
        cartConfigID INT NULL,
        locked VARCHAR(24) NULL
    )
    --
    INSERT INTO #TMP
        ( request, cart, cartConfig, col)
    SELECT
        xmlNode.value('@rq', 'nvarchar(256)') request,
        xmlNode.value('@ct', 'nvarchar(256)') cart,
        xmlNode.value('@cg', 'nvarchar(256)') cartConfig,
        xmlNode.value('@co', 'nvarchar(256)') col
    FROM @xml.nodes('//r') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Declare @requestCountInXML int = @myRowCount

    UPDATE #TMP
    SET cartConfig = ''
    WHERE cartConfig Is Null

    -----------------------------------------------------------
    -- Resolve cart name to cart ID
    -----------------------------------------------------------
    --
    UPDATE #TMP
    SET cartID = LCCart.ID
    FROM #TMP
         INNER JOIN T_LC_Cart AS LCCart
           ON #TMP.cart = LCCart.Cart_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (SELECT * FROM #TMP WHERE cartID IS NULL)
    Begin
        Declare @invalidCart varchar(64) = ''

        SELECT Top 1 @invalidCart = cart
        FROM #TMP
        WHERE cartID IS NULL

        If IsNull(@invalidCart, '') = ''
            Set @message = 'Cart names cannot be blank'
        Else
            Set @message = 'Invalid cart name: ' + @invalidCart
        Set @myError = 510027
        Goto Done
    End

    -----------------------------------------------------------
    -- Resolve cart config name to cart config ID
    -----------------------------------------------------------
    --
    UPDATE #TMP
    SET cartConfigID = CartConfig.Cart_Config_ID
    FROM #TMP
         INNER JOIN T_LC_Cart_Configuration AS CartConfig
           ON #TMP.cartConfig = CartConfig.Cart_Config_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (SELECT * FROM #TMP WHERE cartConfig <> '' AND cartConfigID IS NULL)
    Begin
        Declare @invalidCartConfig varchar(128) = ''

        SELECT Top 1 @invalidCartConfig = cartConfig
        FROM #TMP
        WHERE cartConfig <> '' AND cartConfigID IS NULL

        Set @message = 'Invalid cart config name: ' + @invalidCartConfig
        Set @myError = 510028
        Goto Done
    End

    -----------------------------------------------------------
    -- Batch info
    -----------------------------------------------------------
    --
    UPDATE #TMP
    SET locked = RRB.Locked
    FROM #TMP
       INNER JOIN T_Requested_Run RR
           ON #TMP.request = RR.ID
         INNER JOIN T_Requested_Run_Batches AS RRB
           ON RR.RDS_BatchID = RRB.ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -----------------------------------------------------------
    -- Check for locked batches
    -----------------------------------------------------------

    If Exists (SELECT * FROM #TMP WHERE locked = 'Yes')
    Begin
        Declare @firstLocked int
        Declare @lastLocked int

        SELECT @firstLocked = Min(request),
               @lastLocked = Max(request)
        FROM #TMP
        WHERE locked = 'Yes'

        If @firstLocked = @lastLocked
            Set @message = 'Cannot change requests in locked batches; request ' + Cast(@firstLocked as varchar(12)) + ' is locked'
        Else
            Set @message = 'Cannot change requests in locked batches; locked requests include ' + Cast(@firstLocked as varchar(12)) + ' and ' + + Cast(@lastLocked as varchar(12))

        Set @myError = 510012
        Goto Done
    End

    -----------------------------------------------------------
    -- Disregard unchanged requests
    -----------------------------------------------------------
    --
    DELETE FROM #TMP
    WHERE request IN ( SELECT request
                       FROM #TMP
                            INNER JOIN T_Requested_Run AS RR
                              ON #TMP.request = RR.ID AND
                                 #TMP.cartID = RR.RDS_Cart_ID AND
                                 IsNull(#TMP.cartConfigID, 0) = IsNull(RR.RDS_Cart_Config_ID, 0) AND
                                 CASE
                                     WHEN #TMP.col = '' THEN 0
                                     ELSE Cast(#TMP.col AS int)
                                 END = ISNULL(RR.RDS_Cart_Col, 0) )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to remove unchanged requests'
        Goto Done
    End

    If @debugMode > 0
    Begin
        If @requestCountInXML = @myRowCount
            Set @debugMsg = 'All ' + Cast(@requestCountInXML as varchar(9)) + ' requests were unchanged; nothing to do'
        Else If @myRowCount = 0
            Set @debugMsg = 'Will update all ' + Cast(@requestCountInXML as varchar(9)) + ' requests'
        Else
            Set @debugMsg = 'Will update ' + Cast(@requestCountInXML - @myRowCount as varchar(9)) + ' of ' + Cast(@requestCountInXML as varchar(9)) + ' requests'

        Exec post_log_entry 'Debug', @debugMsg, 'update_lc_cart_request_assignments'

    End

    -----------------------------------------------------------
    -- Update requested runs
    -----------------------------------------------------------
    --
    UPDATE T_Requested_Run
    SET RDS_Cart_ID = #TMP.cartID,
        RDS_Cart_Config_ID = #TMP.cartConfigID,
        RDS_Cart_Col = #TMP.col
    FROM T_Requested_Run RR
         INNER JOIN #TMP
           ON #TMP.request = RR.ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error updating requested runs'
        Goto Done
    End

Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @myRowCount) + ' requested runs updated'
    Exec post_usage_log_entry 'update_lc_cart_request_assignments', @UsageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_lc_cart_request_assignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_lc_cart_request_assignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_lc_cart_request_assignments] TO [Limited_Table_Write] AS [dbo]
GO
