/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunLCCartParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateRequestedRunLCCartParams]
/****************************************************
**
**	Desc: 
**	Changes Parameters for LC Carts
**	to given new values for given list of requested runs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	04/13/2007     - (ticket #424)
**			04/13/2007 grk - added spread function and used MakeTableFromList
**			04/17/2007 grk - added ability to set priority
**			04/17/2007 grk - added 'clear assignments' function
**			04/17/2007 grk - added 'fill_into_gaps' function
**			04/18/2007 grk - added ability to handle blanks to cart/col assignment function
**			04/18/2007 grk - 'fill_into_gaps' function adds requests in canonical sort order
**			04/18/2007 grk - New requests supersede existing assignments in 'fill_into_gaps' function
**			04/18/2007 grk - 'fill_into_gaps' function can handle empty columns and min col count
**			01/27/2010 grk - increased size of @reqRunIDList
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@mode varchar(32), -- 
	@newValue1 varchar(512),
	@newValue2 varchar(512),
	@reqRunIDList varchar(7000)
)
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--
	declare @cartID int
	declare @cols int
	declare @priority int
	declare @seq smallint
	set @seq = 0

	-------------------------------------------------
	-- check for list overflow
	-------------------------------------------------
	
	IF LEN(@reqRunIDList) > 6999
	BEGIN
		RETURN 60
	END

	-------------------------------------------------
	-- Assign the selected requests to the given cart
	-- and to the given column numer
	-------------------------------------------------
	if @mode = 'specific_column'
	begin
		set @cartID = 0
		--
		if @newValue1 = ''
		begin
			set @cartID = 1 -- for 'unknown'
		end
		else
		begin
			SELECT @cartID = ID
			FROM         T_LC_Cart
			WHERE     (Cart_Name = @newValue1)
		end
		--	
		if @newValue2 = ''
		begin
			set @newValue2 = null
		end
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		UPDATE    T_Requested_Run
		SET       RDS_Cart_ID = @cartID, RDS_Cart_Col = @newValue2
		WHERE     (ID IN (SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList)))
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	-------------------------------------------------
	-- Assign the selected requests to the given cart
	-- and spread their column assignements evenly over
	-- the given number of colums
	-------------------------------------------------
	if @mode = 'spread_among_columns'
	begin
		set @cols = cast(@newValue2 as int)
		set @cartID = 0
		--
		SELECT @cartID = ID
		FROM         T_LC_Cart
		WHERE     (Cart_Name = @newValue1)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		UPDATE T_Requested_Run
		SET
			RDS_Cart_ID = @cartID, 
			@seq = RDS_Cart_Col = CASE WHEN @seq >= @cols THEN 1 ELSE @seq + 1 END
		WHERE (ID IN (SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList)))
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	-------------------------------------------------
	-- Clear all cart and column assignments for
	-- all requests currently assigned to given cart
	-------------------------------------------------
	if @mode = 'clear_cart_assignments'
	begin
		set @cartID = 0
		--
		SELECT @cartID = ID
		FROM T_LC_Cart
		WHERE     (Cart_Name = @newValue1)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		UPDATE T_Requested_Run
		SET
			RDS_Cart_ID = 1, RDS_Cart_Col = NULL
		WHERE RDS_Cart_ID = @cartID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	-------------------------------------------------
	-- Set the priority of the selected requests
	-------------------------------------------------
	if @mode = 'priority'
	begin
		set @priority = cast(@newValue1 as int)
		--
		UPDATE    T_Requested_Run
		SET       RDS_priority = @priority
		WHERE     (ID IN (SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList)))
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	-------------------------------------------------
	-- Assign cols to selected requests so as to
	-- fill in 'gaps' in current column loading
	-- for given cart
	-------------------------------------------------
	if @mode = 'fill_into_gaps' AND @reqRunIDList <> ''
	begin
		---------------------------------------------------
		-- resolve cart name to cart ID
		--
		set @cartID = 0
		--
		SELECT @cartID = ID
		FROM T_LC_Cart
		WHERE (Cart_Name = @newValue1)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- create temporary table to hold requested runs
		-- assigned to cart
		--
		CREATE TABLE #XR (
			[request] [int] NOT NULL,
			col [int] NULL,
		) 
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Populate temporary table with run requests 
		-- assigned to this cart
		--
		INSERT INTO #XR
		(request, col)
		SELECT 
			T_Requested_Run.ID, T_Requested_Run.RDS_Cart_Col
		FROM 
			T_Requested_Run
		WHERE
			T_Requested_Run.RDS_Cart_ID = @cartID
		ORDER BY 
			T_Requested_Run.RDS_priority DESC, 
			T_Requested_Run.RDS_BatchID, 
			T_Requested_Run.RDS_Run_Order, 
			T_Requested_Run.ID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Temporary table to hold new requests
		--
		CREATE TABLE #XL (
			[request] [int] NOT NULL,
			os [int] IDENTITY (1, 1) NOT NULL
		) 
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Get selected requests into temporary table 
		--
		INSERT INTO #XL
		(request)
		SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList) INNER JOIN
		T_Requested_Run ON T_Requested_Run.ID = CAST(Item as int)
		ORDER BY 
			T_Requested_Run.RDS_priority DESC, 
			T_Requested_Run.RDS_BatchID, 
			T_Requested_Run.RDS_Run_Order, 
			T_Requested_Run.ID

		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- In the case that there are any new requests 
		-- in the selected list that are already assigned to
		-- cart and col, the list takes precedence.
		--   
		-- Remove such requests from assigned requests temp
		-- table
		--
		DELETE FROM #XR
		WHERE #XR.request IN (SELECT request from #XL)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Temp table to hold column lengths
		--
		CREATE TABLE #XC (
			col [int] NOT NULL,
			length [int] NULL
		) 
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- Establish entries for number of columns
		--
		-- if nothing specified for number of columns
		-- use what is already in table
		--
		if @newValue2 = ''
			SELECT @cols = MAX(DISTINCT col) FROM #XR
		else
			set @cols = cast(@newValue2 as int)
		--
		-- insert a row for each column
		--
		set @seq = 1
		while @seq <= @cols
		begin
			INSERT INTO #XC (col, length) VALUES (@seq, 0)	
			set @seq = @seq + 1
		end

		---------------------------------------------------
		-- Initialize lengths of columns
		--
		UPDATE T
			SET T.length = S.length
		FROM #XC T INNER JOIN
		(
			SELECT col, count(*) as length
			FROM #XR 
			GROUP BY col
		) S ON T.col = S.col

		---------------------------------------------------
		-- Find colums for each new request
		--
		declare @done smallint
		set @done = 0
		--
		declare @curPos smallint
		set @curPos = 0
		--
		declare @nextReq int
		declare @shorCol int
		--
		while @done = 0
		begin
			-- get next new request from table
			--
			set @nextReq = 0
			--
			SELECT TOP 1 @nextReq = request FROM #XL WHERE os > @curPos
			--	
			SELECT @myError = @@error, @myRowCount = @@rowcount

			if @nextReq = 0
				set @done = 1
			else
			begin
				-- get number of col with shortest queue
				--
				SELECT TOP 1 @shorCol = col FROM #XC ORDER BY length, col
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount

				-- add new request to table and assign to shortest col
				--
				INSERT INTO #XR
					(request, col)
				VALUES
					(@nextReq, @shorCol)	
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount

			end -- else
			
			-- increment postition count to get next new request
			--
			set @curPos = @curPos + 1
			
			-- update the column length count
			--
			UPDATE #XC
				SET length = length + 1
			WHERE col = @shorCol
		end -- while

		---------------------------------------------------
		-- Assign the new requests to the given cart and the
		-- column calculated above
		--
		UPDATE T
		SET
			T.RDS_Cart_ID = @cartID,
			T.RDS_Cart_Col = R.col
		FROM T_Requested_Run T
		INNER JOIN 
		(
		SELECT request, col
		FROM #XR
		WHERE #XR.request in (SELECT request FROM #XL)
		) R ON T.ID = R.request
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

	end -- mode

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'UpdateRequestedRunLCCartParams', @UsageMessage

	return 0


GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunLCCartParams] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunLCCartParams] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunLCCartParams] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunLCCartParams] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunLCCartParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunLCCartParams] TO [PNL\D3M580] AS [dbo]
GO
