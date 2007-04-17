/****** Object:  StoredProcedure [dbo].[GenerateLCCartLoadingList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GenerateLCCartLoadingList
/****************************************************
**
**	Desc: 
**		Generates a sample loading list for given LC Cart
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	04/09/2007 (Ticket #424)
**          04/16/2007 grk -- added priority as highest sort attribute
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@LCCartName varchar(128),
	@BlanksFollowingRequests varchar(2048),
	@mode varchar(12) = '', -- 
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	declare @col int

	---------------------------------------------------
	-- 
	---------------------------------------------------
	
	---------------------------------------------------
	-- create temporary table to hold requested runs
	-- assigned to cart
	---------------------------------------------------
	--
	CREATE TABLE #XR (
		[request] [int] NOT NULL,
		col [int] NULL,
		os [int] IDENTITY (1, 2) NOT NULL	
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for requests'
		RAISERROR (@message, 10, 1)
		return 51007
	end
	
	---------------------------------------------------
	-- Populate temporary table with run requests 
	-- assigned to this cart
	---------------------------------------------------

	INSERT INTO #XR
	(request, col)
	SELECT 
		T_Requested_Run.ID, T_Requested_Run.RDS_Cart_Col
	FROM 
		T_Requested_Run INNER JOIN
		T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = T_LC_Cart.ID
	WHERE
		T_LC_Cart.Cart_Name = @LCCartName
	ORDER BY T_Requested_Run.RDS_priority DESC, T_Requested_Run.RDS_BatchID, T_Requested_Run.RDS_Run_Order, T_Requested_Run.ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to populate temporary table for requests'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	---------------------------------------------------
	-- How many columns need to be used for this cart?
	---------------------------------------------------

	declare @numCols int
	set @numCols = 0
	--
	SELECT @numCols = count(DISTINCT col) FROM #XR
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to determine number of columns'
		RAISERROR (@message, 10, 1)
		return 51009
	end

	---------------------------------------------------
	-- Add blanks to table
	---------------------------------------------------
	SET IDENTITY_INSERT #XR ON

	if @BlanksFollowingRequests <> ''
	begin
		--
		INSERT INTO #XR ([request], col, os)
		SELECT 0, col, os + 1
		FROM #XR
		WHERE [request] in (SELECT Item FROM dbo.MakeTableFromList(@BlanksFollowingRequests))
	end	
/**/
	---------------------------------------------------
	-- Pad out ends of column queues with blanks
	---------------------------------------------------

	-- how many samples in longest column queue?
	--
	declare @maxSamples int
	set @maxSamples = 0
	--
	SELECT @maxSamples = MAX(T.X) 
	FROM (
	SELECT COUNT(*) AS X 
	FROM #XR 
	GROUP BY col
	) T

	set @col = 1
	--
	declare @qLen int
	declare @padCnt int
	declare @c int
	declare @maxOS int
	--
	SELECT @maxOS = max(os) FROM #XR
	--
	while @col <= @numCols
	begin
		-- how many samples in col queue?
		--
		SELECT @qLen = count(*) FROM #XR WHERE col = @col
		
		-- number of blanks to add
		--
		set @padCnt = @maxSamples - @qLen
		
		-- append blanks
		--
		set @c = 0
		while @c < @padCnt
		begin
			INSERT INTO #XR ([request], col, os)
			VALUES (0, @col, @maxOS + 1)
			set @maxOS = @maxOS + 1
			set @c = @c + 1
		end
		set @col = @col + 1
	end

	---------------------------------------------------
	-- create temporary table to sequence samples
	-- for cart
	---------------------------------------------------
	--
	CREATE TABLE #XS (
		[request] [int] NOT NULL,
		col [int] NULL,
		seq [int] NULL,
		os [int] IDENTITY (1, 1) NOT NULL	
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for sequencing'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- copy contents of original request table to
	-- sequence generating table
	---------------------------------------------------

	INSERT INTO #XS
	(request, col)
	SELECT request, col FROM #XR
	ORDER BY os
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to populate temporary table for sequencing'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	DROP TABLE #XR
	
	---------------------------------------------------
	-- Sequentially number all the samples for each
	-- column so that columns rotate
	---------------------------------------------------
	
	-- first, number the sequence field (by increment of 10)
	-- for each request in each set for each cart column
	--
	declare @seq int
	set @seq = 0
	--
	set @col = 1
	--
	while @col <= @numCols
	begin
		UPDATE    #XS
		SET @seq = seq = (@seq + 10)
		WHERE (col = @col)

		set @seq = 0
		set @col = @col + 1
	end

	-- next bump the sequence field by 
	-- adding the column number
	--
	UPDATE    #XS
	SET seq = seq + col

	---------------------------------------------------
	-- create temporary table to hold the final sequence
	---------------------------------------------------
	--
	CREATE TABLE #XF (
		[request] [int] NOT NULL,
		col int,
		seq [int] IDENTITY (1, 1) NOT NULL	
	) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table for final sequence'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- populate the final sequence table
	---------------------------------------------------

	INSERT INTO #XF
	(request, col)
	SELECT request, col FROM #XS
	ORDER BY seq
	
	DROP TABLE #XS

	---------------------------------------------------
	-- Output final report
	---------------------------------------------------

	SELECT 
	#XF.seq AS [Sequence],
	CASE WHEN #XF.request = 0 THEN '(blank)' ELSE t_Requested_Run.rds_Name END as Name,
	#XF.request AS Request,
	#XF.col AS [Column#],
	t_Experiments.Experiment_num AS Experiment
	, T_Requested_Run.RDS_priority AS Priority, T_Requested_Run.RDS_BatchID AS Batch, T_Requested_Run.RDS_Run_Order AS [Batch Run Order]
	FROM   
	#XF
	LEFT OUTER JOIN t_Requested_Run
		ON #XF.Request = t_Requested_Run.Id
	LEFT OUTER JOIN t_Experiments
		ON t_Requested_Run.exp_Id = t_Experiments.exp_Id
	ORDER BY #XF.seq
    
 return @myError

GO
GRANT EXECUTE ON [dbo].[GenerateLCCartLoadingList] TO [DMS_LC_Column_Admin]
GO
GRANT EXECUTE ON [dbo].[GenerateLCCartLoadingList] TO [DMS_RunScheduler]
GO
