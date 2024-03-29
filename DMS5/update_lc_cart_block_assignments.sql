/****** Object:  StoredProcedure [dbo].[update_lc_cart_block_assignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_lc_cart_block_assignments]
/****************************************************
**
**  Desc:
**  Set LC cart and col assignments for requested run blocks
**
**  This procedure was last used in 2012
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/15/2010
**          09/02/2011 mem - Now calling post_usage_log_entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @cartAssignmentList text,
    @mode varchar(32), --
    @message varchar(512) output
)
AS
    SET NOCOUNT ON

    declare @myError int = 0
    declare @myRowCount int = 0

    DECLARE @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON
    SET @xml = @cartAssignmentList

    SET @message = ''

    -- Uncomment to log the XML for debugging purposes
    -- exec post_log_entry 'Debug', @cartAssignmentList, 'update_lc_cart_block_assignments'

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_lc_cart_block_assignments', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    -----------------------------------------------------------
    -- create and populate temp table with block assignments
    -----------------------------------------------------------
    --
    CREATE TABLE #TMP (
        batchID int,
        BLOCK   int,
        cart    varchar(64),
        cartID  int NULL,
        col     int
    )
    --
    INSERT INTO #TMP
        ( batchID, block, cart , col)
    SELECT
        xmlNode.value('@bt', 'nvarchar(256)') batchID,
        xmlNode.value('@bk', 'nvarchar(256)') block,
        xmlNode.value('@ct', 'nvarchar(256)') cart,
        xmlNode.value('@co', 'nvarchar(256)') col
    FROM @xml.nodes('//r') AS R(xmlNode)

    -----------------------------------------------------------
    -- resolve cart name to cart ID
    -----------------------------------------------------------
    --
    UPDATE #TMP
    SET cartID = ISNULL(T_LC_Cart.ID, 1)
    FROM #TMP
         LEFT OUTER JOIN dbo.T_LC_Cart
           ON cart = Cart_Name


    -- FUTURE: verify valid cart names

    -----------------------------------------------------------
    -- create and populate temp table with request assignments
    -----------------------------------------------------------
    --
    CREATE TABLE #REQ (
        request int,
        cartID  int,
        col     int
    )
    --
    INSERT INTO #REQ( request,
                      cartid,
                      col )
    SELECT ID,
           cartID,
           col
    FROM T_Requested_Run
         INNER JOIN #TMP
           ON batchID = RDS_BatchID AND
              BLOCK = RDS_Block

    -----------------------------------------------------------
    -- update requested runs
    -----------------------------------------------------------
    --
    UPDATE T_Requested_Run
    SET RDS_Cart_ID = cartID,
        RDS_Cart_Col = col
    FROM T_Requested_Run
         INNER JOIN #REQ
           ON request = ID
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = 'Updated ' + convert(varchar(12), @myRowCount) + ' requested run'
    If @myRowCount <> 1
        Set @UsageMessage = @UsageMessage + 's'
    Exec post_usage_log_entry 'update_lc_cart_block_assignments', @UsageMessage

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_lc_cart_block_assignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_lc_cart_block_assignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_lc_cart_block_assignments] TO [Limited_Table_Write] AS [dbo]
GO
