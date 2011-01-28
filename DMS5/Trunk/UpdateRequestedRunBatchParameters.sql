/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBatchParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateRequestedRunBatchParameters
/****************************************************
**
**	Desc: 
**	Change run blocking parameters 
**	given by lists
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 02/09/2010
**		02/16/2010 grk - eliminated batchID from arg list
**    
*****************************************************/
	@blockingList text,
	@mode varchar(32), -- 
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''

	-----------------------------------------------------------
	-- temp table to hold new parameters
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (
		Parameter VARCHAR(32),
		Request INT,
		Value VARCHAR(128),
		ExistingValue VARCHAR(128) NULL
	)

	IF @mode = 'update'
	BEGIN --<a>
	-----------------------------------------------------------
	-- populate temp table with new parameters
	-----------------------------------------------------------
	--
		SET @xml = @blockingList
		--
		INSERT INTO #TMP
			( Parameter, Request, Value )
		select
			xmlNode.value('@t', 'nvarchar(256)') Parameter,
			xmlNode.value('@i', 'nvarchar(256)') Request,
			xmlNode.value('@v', 'nvarchar(256)') Value
		FROM @xml.nodes('//r') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to convert list'
			return 51009
		end

		-----------------------------------------------------------
		-- normalize parameter names
		-----------------------------------------------------------
		--
		UPDATE #TMP SET Parameter = 'Blocking Factor' WHERE Parameter = 'BF'
		UPDATE #TMP SET Parameter = 'Block' WHERE Parameter = 'BK'
		UPDATE #TMP SET Parameter = 'Run Order' WHERE Parameter ='RO'

		-----------------------------------------------------------
		-- remove temp table entries that are same as in db
		-----------------------------------------------------------
		--
		UPDATE #TMP
		SET ExistingValue = CASE 
							WHEN #tmp.Parameter = 'Block' THEN RDS_Block
							WHEN #tmp.Parameter = 'Run Order' THEN RDS_Run_Order
							WHEN #tmp.Parameter = 'Blocking Factor' THEN RDS_Blocking_Factor
							ELSE ''
							END 
		FROM #TMP INNER JOIN T_Requested_Run ON #TMP.Request = dbo.T_Requested_Run.ID
		--
		DELETE FROM #TMP WHERE (#TMP.Value = #TMP.ExistingValue)
		--
	END --<a>

	-----------------------------------------------------------
	-- anything left to update?
	-----------------------------------------------------------
	--
	IF NOT EXISTS (SELECT * FROM #TMP)
	BEGIN
		set @message = 'No blocking factors to update'
		return 0	
	END

	-------------------------------------------------
	-- verify batch
	-------------------------------------------------
	--
	IF @mode = 'update'
	BEGIN --<b>

		-------------------------------------------------
		-- populate temp table with batch IDs from
		-- requests in lists and make sure there is
		-- exactly one batch for all the requests
		-------------------------------------------------
		--
		CREATE TABLE #BAT (
			BatchID INT
		)

		INSERT INTO #BAT
				( BatchID)
		SELECT DISTINCT RDS_BatchID
		FROM         T_Requested_Run
		WHERE ID IN (SELECT Request FROM #TMP)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying get batch ID from requests'
			return 51040
		end
		--
		if @myRowCount <> 1
		begin
			set @message = 'Requests are not all from the same batch'
			return 51041
		end

		-------------------------------------------------
		-- get batch from temp table and verify it is
		-- not 0
		-------------------------------------------------
		--
		DECLARE @batchID int
		SET @batchID = 0
		--
		SELECT 
			@batchID = #BAT.BatchID 
		FROM 
			#BAT
		--
		IF @batchID = 0
		begin
			set @message = 'Batch ID cannot be 0'
			return 51170
		end

		-------------------------------------------------
		-- look up batch properties and verify conditions
		-------------------------------------------------
		--
		declare @lock varchar(12)
		--
		SELECT @lock = Locked
		FROM T_Requested_Run_Batches
		WHERE (ID = @batchID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to find batch in batch table'
			return 51007
		end
		--
		if @myRowCount = 0
		begin
			set @message = 'Could not find batch ' + CONVERT(VARCHAR(12), @batchID) + 'in batch table'
			return 51008
		end

		if @lock = 'yes'
		begin
			set @message = 'Cannot change a locked batch'
			return 51170
		end

	END --<b>

	-----------------------------------------------------------
	-- actually do update
	-----------------------------------------------------------
	--
	IF @mode = 'update'
	BEGIN --<c>

		declare @transName varchar(32)
		set @transName = 'UpdateRequestedRunBatchParameters'

		begin transaction @transName

		UPDATE T_Requested_Run
		SET RDS_Blocking_Factor = #TMP.Value
		FROM 
			T_Requested_Run INNER JOIN
			#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
		WHERE 
			#TMP.Parameter = 'Blocking Factor'
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error trying to update batch paramater'
			return 51030
		end

		UPDATE T_Requested_Run
		SET RDS_Block = #TMP.Value
		FROM 
			T_Requested_Run INNER JOIN
			#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
		WHERE 
			#TMP.Parameter = 'Block'
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error trying to update batch paramater'
			return 51030
		end
		
		UPDATE T_Requested_Run
		SET RDS_Run_Order = #TMP.Value
		FROM 
			T_Requested_Run INNER JOIN
			#TMP ON #TMP.Request = dbo.T_Requested_Run.ID
		WHERE 
			#TMP.Parameter = 'Run Order'
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error trying to update batch paramater'
			return 51030
		end

		commit transaction @transName

		-----------------------------------------------------------
		-- convert changed items to XML for logging
		-----------------------------------------------------------
		--
		DECLARE @changeSummary varchar(max)
		set @changeSummary = ''
		--
		SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), Request) + '" t="' + Parameter + '" v="' + Value + '" />'
		FROM #TMP
		
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
	END --<c>

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--

	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBatchParameters] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchParameters] TO [Limited_Table_Write] AS [dbo]
GO
