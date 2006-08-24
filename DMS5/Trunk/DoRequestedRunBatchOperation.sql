/****** Object:  StoredProcedure [dbo].[DoRequestedRunBatchOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure DoRequestedRunBatchOperation
/****************************************************
**
**	Desc: 
**	Perform operations on requested run batches 
**	that only admins are allowed to do
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/12/2006
**    
*****************************************************/
(
	@batchID int,
	@mode varchar(12), -- '', '', ''
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
		
	declare @result int

	---------------------------------------------------
	-- Is batch in table?
	---------------------------------------------------
	declare @batchExists int
	declare @lock varchar(12)
	set @batchExists = 0
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
	
	set @batchExists = @myRowCount

	---------------------------------------------------
	-- Lock run order
	---------------------------------------------------

	if @mode = 'LockBatch'
	begin
		if @batchExists > 0
		begin
			UPDATE    T_Requested_Run_Batches
			SET              Locked = 'Yes'
			WHERE     (ID = @batchID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Failed trying to lock batch'
				RAISERROR (@message, 10, 1)
				return 51140
			end
		end
		return 0
	end

	---------------------------------------------------
	-- Unlock run order
	---------------------------------------------------

	if @mode = 'UnlockBatch'
	begin
		if @batchExists > 0
		begin
			UPDATE    T_Requested_Run_Batches
			SET              Locked = 'No'
			WHERE     (ID = @batchID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Failed trying to unlock table'
				RAISERROR (@message, 10, 1)
				return 51140
			end
		end
		return 0
	end

	---------------------------------------------------
	-- Calculate batch run order
	---------------------------------------------------

	if @mode = 'BatchOrder'
	begin
		if @lock = 'yes'
			begin
				set @message = 'Cannot update run order of locked batch'
				RAISERROR (@message, 10, 1)
				return 51170
			end
		else
			begin
				exec @result = UpdateRequestedRunBatchOrder @batchID, @message output
				if @result <> 0
				begin
					RAISERROR (@message, 10, 1)
					return 51001
				end
				return 0
			end
	end


	---------------------------------------------------
	-- remove current member requests from batch
	---------------------------------------------------

	if @mode = 'FreeMembers' or @mode = 'delete'
	begin
		if @lock = 'yes'
			begin
				set @message = 'Cannot remove member requests of locked batch'
				RAISERROR (@message, 10, 1)
				return 51170
			end
		else
			begin
			UPDATE T_Requested_Run
			SET RDS_BatchID = 0
			WHERE (RDS_BatchID = @batchID)			
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Failed to remove member requests of batch'
				RAISERROR (@message, 10, 1)
				return 51001
			end
			if @mode = 'FreeMembers' return 0
		end
	end
	
	---------------------------------------------------
	-- Delete batch
	---------------------------------------------------

	if @mode = 'delete'
	begin
		if @lock = 'yes'
			begin
				set @message = 'Cannot delete locked batch'
				RAISERROR (@message, 10, 1)
				return 51170
			end
		else
			begin
				DELETE FROM T_Requested_Run_Batches
				WHERE     (ID = @batchID)			
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @message = 'Failed trying to unlock table'
					RAISERROR (@message, 10, 1)
					return 51140
				end
				return 0
			end
	end


	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = ''
	begin
		return 0
	end -- mode ''
	
	
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @message = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@message, 10, 1)
	return 51222

GO
GRANT EXECUTE ON [dbo].[DoRequestedRunBatchOperation] TO [DMS_RunScheduler]
GO
