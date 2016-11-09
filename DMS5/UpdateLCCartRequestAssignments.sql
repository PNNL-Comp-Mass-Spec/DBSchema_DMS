/****** Object:  StoredProcedure [dbo].[UpdateLCCartRequestAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateLCCartRequestAssignments
/****************************************************
**
**	Desc: 
**	Set LC cart and col assignments for requested runs
**
**	Example XML for @cartAssignmentList
**		<r rq="543451" ct="Andromeda" co="1" />
**		<r rq="543450" ct="Andromeda" co="2" />
**		<r rq="543449" ct="Andromeda" co="1" />
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	03/10/2010
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			11/07/2016 mem - Add optional logging via PostLogEntry
**    
*****************************************************/
(
	@cartAssignmentList text,		-- XML (see above)
	@mode varchar(32),				-- Unused
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

	-- Uncomment to log the XML for debugging purposes
	-- exec PostLogEntry 'Debug', Cast(@cartAssignmentList As varchar(4096)), 'UpdateLCCartRequestAssignments'

	-----------------------------------------------------------
	-- create and populate temp table with block assignments
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (
		request INT,
		cart VARCHAR(64),
		col	VARCHAR(12),
		cartID INT NULL,
		locked VARCHAR(24) NULL 
	)
	--
	INSERT INTO #TMP
		( request, cart , col)
	SELECT
		xmlNode.value('@rq', 'nvarchar(256)') request,
		xmlNode.value('@ct', 'nvarchar(256)') cart,
		xmlNode.value('@co', 'nvarchar(256)') col
	FROM @xml.nodes('//r') AS R(xmlNode)

	-----------------------------------------------------------
	-- resolve cart name to cart ID
	-----------------------------------------------------------
	--
	UPDATE #TMP
	SET
		cartID = T_LC_Cart.ID
	FROM
		#TMP
		LEFT OUTER JOIN dbo.T_LC_Cart ON cart = Cart_Name

		
	IF EXISTS (SELECT * FROM #TMP WHERE cartID IS NULL)
	BEGIN
		SET @message = 'Invalid cart name'
		SET @myError = 510027
		GOTO Done	
	END 

	-----------------------------------------------------------
	-- batch info
	-----------------------------------------------------------
	--
	UPDATE #TMP
	SET locked = dbo.T_Requested_Run_Batches.Locked
	FROM #TMP 
	INNER JOIN dbo.T_Requested_Run ON request = dbo.T_Requested_Run.ID
	INNER JOIN dbo.T_Requested_Run_Batches ON dbo.T_Requested_Run.RDS_BatchID = dbo.T_Requested_Run_Batches.ID

	-----------------------------------------------------------
	-- check for locked batches
	-----------------------------------------------------------
	
	IF EXISTS (SELECT * FROM #TMP WHERE locked = 'Yes')
	BEGIN
		SET @message = 'Cannot change requests in locked batches'
		SET @myError = 510012
		GOTO Done
	END 

	-----------------------------------------------------------
	-- disregard unchanged requests
	-----------------------------------------------------------
	--
	DELETE FROM
		#TMP
	WHERE
		EXISTS ( 
			SELECT
				*
			FROM
				dbo.T_Requested_Run
			WHERE
				request = ID
				AND cartID = RDS_Cart_ID
				AND CASE WHEN col = '' THEN 0 ELSE CONVERT(INT, col) END = ISNULL(RDS_Cart_Col, 0) 
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to remove unchanged requests'
		GOTO Done
	end

	-----------------------------------------------------------
	-- update requested runs
	-----------------------------------------------------------
	--
	UPDATE T_Requested_Run
	SET
		RDS_Cart_ID = cartID,
		RDS_Cart_Col = col
	FROM
		T_Requested_Run
		INNER JOIN #TMP ON request =ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating requested runs'
		GOTO Done
	end

Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = Convert(varchar(12), @myRowCount) + ' requested runs updated'
	Exec PostUsageLogEntry 'UpdateLCCartRequestAssignments', @UsageMessage

	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[UpdateLCCartRequestAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartRequestAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartRequestAssignments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLCCartRequestAssignments] TO [PNL\D3M580] AS [dbo]
GO
