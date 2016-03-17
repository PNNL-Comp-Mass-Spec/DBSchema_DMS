/****** Object:  StoredProcedure [dbo].[UpdateLCCartBlockAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateLCCartBlockAssignments]
/****************************************************
**
**	Desc: 
**	Set LC cart and col assignments for 
**  requested run blocks
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	02/15/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@cartAssignmentList text,
	@mode varchar(32), -- 
	@message varchar(512) output
)
As
	SET NOCOUNT ON 

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON
	SET @xml = @cartAssignmentList

	SET @message = ''

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
	Exec PostUsageLogEntry 'UpdateLCCartBlockAssignments', @UsageMessage

	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[UpdateLCCartBlockAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartBlockAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartBlockAssignments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartBlockAssignments] TO [PNL\D3M580] AS [dbo]
GO
