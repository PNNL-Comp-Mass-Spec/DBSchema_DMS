/****** Object:  StoredProcedure [dbo].[GenerateLCCartLoadingList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GenerateLCCartLoadingList
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
**          04/16/2007 grk - added priority as highest sort attribute
**          06/07/2007 grk - added EMSL user columns to output (Ticket #488)
**			07/31/2007 mem - now returning Dataset Type for each request (Ticket #505)
**			08/27/2007 grk - add ability to start columns with a blank (Ticket #517)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@LCCartName varchar(128),
	@BlanksFollowingRequests varchar(2048),
	@ColumnsWithLeadingBlanks varchar(256),
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
	-- Add following blanks to table
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

	---------------------------------------------------
	-- Add column lead blanks to table
	---------------------------------------------------
	if @ColumnsWithLeadingBlanks <> ''
	begin
		--
		INSERT INTO #XR ([request], col, os)
		SELECT 0, CAST(Item as int), 0
		FROM dbo.MakeTableFromList(@ColumnsWithLeadingBlanks)
	end	

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
		-- Note that the following Update query uses a bit of Sql Server query witchcraft
		--  The @seq variable starts off at 0, and the seq column in the first row will thus be assigned a value of @seq+10 --> 10
		--  The result of this math is stored in @seq so that in the next row the seq column is assigned a value of 10+10 --> 20
		--  This process continues, resulting in the seq column being updated to have values of 10, 20, 30, 40, 50, etc. (for a given column)
		--  This operation assumes that Sql Server will order things by the identity field (os)
		--  An alternative approach would be to add another while loop with explicit row-by-row updates, but since the 
		--   "@seq = seq = (@seq + 10)" trick works, we're using it owing to its increased efficiency

		UPDATE    #XS
		SET @seq = seq = (@seq + 10)
		WHERE (col = @col)

		set @seq = 0
		set @col = @col + 1
	end

	-- Next bump the sequence field up by adding the column number
	-- This assumes that there are 9 or fewer columns (since the seq values 10 units apart)
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
		seq [int] IDENTITY (1, 1) NOT NULL,
		blankSeq int null
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
	-- Check whether all of the entries in #XF have the same
	--  dataset type.  If they do, then that type will be
	--  reported for the blanks.  If not, but if the type is
	--  the same in 75% of the the entries, then the most common
	--  dataset type will be returned.  Otherwise return Null
	--  for the dataset type for blanks
	---------------------------------------------------
	
	declare @MatchCount int
	declare @RequestCountTotal int
	declare @DSTypeForBlanks varchar(64)
	
	set @MatchCount = 0
	set @RequestCountTotal = 0
	set @DSTypeForBlanks = Null

	SELECT TOP 1 
		@DSTypeForBlanks = DSType.DST_Name,
		@MatchCount = COUNT(*)
	FROM T_Requested_Run RR INNER JOIN
		 T_DatasetTypeName DSType ON RR.RDS_type_ID = DSType.DST_Type_ID INNER JOIN
		 #XF ON RR.ID = #XF.request
	GROUP BY DSType.DST_Name
	ORDER BY COUNT(*) DESC

	SELECT @RequestCountTotal = COUNT(*)
	FROM T_Requested_Run RR INNER JOIN
		 #XF ON RR.ID = #XF.request

	If @MatchCount < @RequestCountTotal * 0.75
		Set @DSTypeForBlanks = Null
		
	---------------------------------------------------
	-- Generate sequential numbers for all blanks
	---------------------------------------------------
/**/
	set @seq = 0
	--
	UPDATE #XF
	SET @seq = blankSeq = (@seq + 1)
	WHERE request = 0

	---------------------------------------------------
	-- Output final report
	---------------------------------------------------
        
	SELECT 
		#XF.seq AS [Sequence],
		CASE WHEN #XF.request = 0 THEN 'Blank-' + CAST(#XF.blankSeq as varchar(12)) ELSE RR.rds_Name END AS [Name],
		#XF.request AS Request,
		#XF.col AS [Column#],
		E.Experiment_num AS Experiment,
		RR.RDS_priority AS Priority, 
		CASE WHEN #XF.request = 0 THEN @DSTypeForBlanks ELSE DSType.DST_Name END AS [Type], 
		RR.RDS_BatchID AS Batch, 
		RR.RDS_Block as Block, 
		RR.RDS_Run_Order AS [Batch Run Order],
		EUT.Name AS [EMSL Usage Type], 
		RR.RDS_EUS_Proposal_ID AS [EMSL Proposal ID], 
		dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS [EMSL Users List]
	FROM T_Experiments E INNER JOIN
		 T_Requested_Run RR ON E.Exp_ID = RR.Exp_ID INNER JOIN
		 T_EUS_UsageType EUT ON RR.RDS_EUS_UsageType = EUT.ID INNER JOIN
		 T_DatasetTypeName DSType ON RR.RDS_type_ID = DSType.DST_Type_ID RIGHT OUTER JOIN
		 #XF ON RR.ID = #XF.request
	ORDER BY #XF.seq

    
 return @myError


GO
GRANT EXECUTE ON [dbo].[GenerateLCCartLoadingList] TO [DMS_LC_Column_Admin]
GO
GRANT EXECUTE ON [dbo].[GenerateLCCartLoadingList] TO [DMS_RunScheduler]
GO
