/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBatchOrder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateRequestedRunBatchOrder]
/****************************************************
**
**	Desc: 
**    Calculates run order for given batch of run requests
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth: 	grk
**	Date: 	12/09/2005
**          03/21/2006 grk - added max block number stuff
**          04/24/2006 grk - fixed 30 block max limit
**          07/12/2006 grk - added last updated batch
**			09/02/2011 mem - Now calling PostUsageLogEntry
**
*****************************************************/
(
    @batchID int,
	@message varchar(512) output
)
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''


	declare @done int
	declare @num int

	---------------------------------------------------
	-- create temporary table for random sorting of 
	-- requests in batch
	---------------------------------------------------
	--
	CREATE TABLE #XR (
		[Request_ID] [int] NOT NULL ,
		Random float,
		seq [int] IDENTITY (1, 1) NOT NULL	
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for requests'
		goto Done
	end


	---------------------------------------------------
	-- get requests in batch into temporary table
	---------------------------------------------------
	--
	INSERT INTO #XR
	(Request_ID, Random)
	SELECT     ID, 0 
	FROM         T_Requested_Run
	WHERE     (RDS_BatchID = @batchID)
	ORDER BY RDS_Blocking_Factor
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to load temporary table XR'
		goto Done
	end

	---------------------------------------------------
	-- place random values in Random column
	-- for sorting
	---------------------------------------------------
	--
	set @num = 1
	set @done = 0
	declare @rid int
	while @done = 0 AND @num < 300
	begin
		SELECT @rid = Request_ID 
		FROM #XR 
		WHERE seq = @num
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Failed get next row from XR'
			goto Done
		end
		
		-- bump the index
		--
		set @num = @num + 1

		if @myRowCount = 0 
		-- if none found, we are done
		begin
			set @done = 1
		end
		else
		begin
			-- otherwise, upate entry with random value
			--
			UPDATE #XR
			SET Random = rand()
			WHERE Request_ID = @rid
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Failed to update random values'
				goto Done
			end
		end
	end

	---------------------------------------------------
	-- create temporary table for all requests in batch 
	---------------------------------------------------
	--
	CREATE TABLE #XT (
		[Request_ID] [int] NOT NULL ,
		[Block] [int] NULL ,
		Blocking_Factor varchar(64)
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table XT'
		goto Done
	end

	---------------------------------------------------
	-- load temporary table with all requests in batch 
	-- in random order
	---------------------------------------------------
	--
	INSERT INTO #XT
	(Request_ID, Block, Blocking_Factor)
	SELECT T_Requested_Run.ID, 0, RDS_Blocking_Factor
	FROM 
	T_Requested_Run INNER JOIN
	#XR ON #XR.Request_ID = T_Requested_Run.ID
	ORDER BY RDS_Blocking_Factor, #XR.Random
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to load temporary table XT'
		goto Done
	end

	---------------------------------------------------
	-- create temporary table for different blocking factors
	---------------------------------------------------
	--
	CREATE TABLE #BF (
		[id] [int] IDENTITY (1, 1) NOT NULL,
		BlockingFactor varchar(64),
		numRequests int
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for blocking factors'
		goto Done
	end

	---------------------------------------------------
	-- load temporary table with distinct blocking factors
	---------------------------------------------------
	--
	INSERT INTO #BF
	(BlockingFactor, numRequests)
	SELECT  RDS_Blocking_Factor, COUNT(*) AS numRequests
	FROM   T_Requested_Run
	WHERE (RDS_BatchID = @batchID)
	GROUP BY RDS_Blocking_Factor
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to load blocking factors'
		goto Done
	end

	---------------------------------------------------
	-- set maximum number of blocks
	---------------------------------------------------
	declare @maxBlocks int
	set @maxBlocks = 5
	--
	SELECT @maxBlocks = MIN(numRequests)
	FROM #BF
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error while finding max blocks'
		goto Done
	end
	--
	if @maxBlocks = 0
	begin
		set @message = 'Invalid maximum block size calculated'
		goto Done
	end
	
	---------------------------------------------------
	-- for each blocking factor, establish block numbers for each request
	---------------------------------------------------
	--
	declare @factor varchar(64)
	set @factor = ''
	set @num = 1
	set @done = 0
	while not @done > 0
	begin
		-- get next blocking factor
		--
		SELECT @factor = BlockingFactor
		FROM #BF
		WHERE id = @num
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Failed to get next blocking factor'
			goto Done
		end
		
		-- bump the index
		--
		set @num = @num + 1
		
		-- did we find another blocking factor?
		--
		if @myRowCount = 0 
			-- if none found, we are done
			begin
				set @done = 1
			end
		else
			begin
				-- otherwise, assign sequential block numbers
				-- to all requests with current blocking factor
				--
				declare @seq int
				set @seq = 0
				UPDATE    #XT
				SET @seq = Block = (@seq % @maxBlocks) + 1
				WHERE (Blocking_Factor = @factor)
				--
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @message = 'Failed to assign block numbers for blocking factor'
					goto Done
				end
			end
	end

	---------------------------------------------------
	-- create temporary table for batch run order
	---------------------------------------------------
	--
	--
	CREATE TABLE #YT (
		[Request_ID] [int] NOT NULL ,
		[Block] [int] NULL ,
		[Run_Order] [int] IDENTITY (1, 1) NOT NULL
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table YT'
		goto Done
	end

	---------------------------------------------------
	-- populate temp table with requests in run order
	---------------------------------------------------
	--
	INSERT INTO #YT
	(Request_ID, Block)
	SELECT Request_ID, Block
	FROM #XT
	ORDER BY Block, NEWID()
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to load temporary table YT'
		goto Done
	end

	---------------------------------------------------
	-- update requests with block number and run order
	---------------------------------------------------
	--
	UPDATE T_Requested_Run
	SET T_Requested_Run.RDS_Block = #YT.Block, T_Requested_Run.RDS_Run_Order = #YT.Run_Order
	FROM T_Requested_Run INNER JOIN #YT ON T_Requested_Run.ID = #YT.Request_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update run requests'
		goto Done
	end

	---------------------------------------------------
	-- update last ordered date in batch
	---------------------------------------------------
	--
	UPDATE T_Requested_Run_Batches
	SET Last_Ordered = GETDATE()
	WHERE (ID = @batchID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update "last ordered" for batch'
		goto Done
	end

Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Batch: ' + Convert(varchar(12), @batchID)
	Exec PostUsageLogEntry 'UpdateRequestedRunBatchOrder', @UsageMessage

	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchOrder] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchOrder] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchOrder] TO [PNL\D3M580] AS [dbo]
GO
