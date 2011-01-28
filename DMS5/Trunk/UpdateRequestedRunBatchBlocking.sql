/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunBatchBlocking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateRequestedRunBatchBlocking
/****************************************************
**
**	Desc: 
**	Changes run blocking properties 
**	to given new value for given list of requested runs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/12/2006
**		      4/25/2006 grk - added more commands
**    
*****************************************************/
	@batchID int,
	@reqRunIDList varchar(2048),
	@newValue varchar(512),
	@mode varchar(32), -- 
	@message varchar(512) output
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--
	declare @id int
	--
	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	-------------------------------------------------
	-- Cannot change locked batch
	-------------------------------------------------
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
		set @message = 'Failed trying to find batch in batch table'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	if @lock = 'yes'
	begin
		set @message = 'Cannot change a locked batch'
		RAISERROR (@message, 10, 1)
		return 51170
	end

	-------------------------------------------------
	if @mode = 'blocking_factor'
	begin
		UPDATE T_Requested_Run
		SET	 RDS_Blocking_Factor = @newValue
		WHERE ID in 
		(
			SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList)
		)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			RAISERROR ('operation failed: "%d"', 10, 1, @myError )
			return 51310
		end	
	end

	-------------------------------------------------
	if @mode = 'remove_requests'
	begin
		UPDATE T_Requested_Run
		SET	 RDS_BatchID = 0
		WHERE ID in 
		(
			SELECT Item FROM dbo.MakeTableFromList(@reqRunIDList)
		)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			RAISERROR ('operation failed: "%d"', 10, 1, @myError)
			return 51310
		end	
	end
	
	-------------------------------------------------
	if @mode = 'calc_run_order'
	begin
		exec @myError = UpdateRequestedRunBatchOrder @batchID, @message output
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return 51001
		end
	end


	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBatchBlocking] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunBatchBlocking] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchBlocking] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchBlocking] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunBatchBlocking] TO [PNL\D3M580] AS [dbo]
GO
