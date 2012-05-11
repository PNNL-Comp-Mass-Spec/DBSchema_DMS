/****** Object:  StoredProcedure [dbo].[SetRestoreTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetRestoreTaskComplete

/****************************************************
**
**	Desc: 
**		Sets dataset state and archive state of dataset 
**		record given by @datasetNum
**		according to given completion code and purge code
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/12/2004
**			  08/12/2004 grk - added setting for purge holdoff date
**			  11/16/2006 grk - changed @purgeHoldoffInterval to 5 days
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode <> 0 -> failure
	@purgeCode int = 0, -- @purgeCode = 0 -> Archive state = complete, @purgeCode <> 0 -> Archive state = purged
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @datasetID int
 	declare @result int
 	
 	declare @purgeHoldoffInterval int
 	set  @purgeHoldoffInterval = 5
		
	---------------------------------------------------
	-- resolve dataset into ID
	---------------------------------------------------
	--
	SELECT 
		@datasetID = T_Dataset.Dataset_ID
	FROM   T_Dataset 
	WHERE     (Dataset_Num = @datasetNum)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset ID for dataset ' + @datasetNum
		goto done
	end

	---------------------------------------------------
	-- check current dataset state
	---------------------------------------------------

	declare @currentState as int
	set @currentState = 0
	--
	SELECT @currentState = DS_state_ID
	FROM T_Dataset
	WHERE (Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get current state for dataset ' + @datasetNum
		goto done
	end
	
	if @currentState <> 11
	begin
		set @myError = 1
		set @message = 'Current state incorrect for dataset ' + @datasetNum
		goto done
	end

	---------------------------------------------------
	-- choose dataset state and archive state
	---------------------------------------------------
	
	declare @datasetState int
	declare @archiveState int

	if @completionCode <> 0
		set @datasetState = 12 -- recovery failed
	else
		begin
			set @datasetState = 3 -- dataset complete
			if @purgeCode = 0
				set @archiveState = 3
			else
				set @archiveState = 4
		end	

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetRestoreTaskComplete'
	begin transaction @transName

	---------------------------------------------------
	-- update dataset state
	---------------------------------------------------
	--
	UPDATE T_Dataset
	SET    DS_state_ID = @datasetState 
	WHERE  (Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update dataset operation failed'
		set @myError = 99
		rollback transaction @transName
		goto done
	end
	
	---------------------------------------------------
	-- don't touch archive state if recovery failed
	---------------------------------------------------
	if @datasetState = 12 
	begin
		commit transaction @transName
		goto done
	end

	---------------------------------------------------
	-- update archive state
	---------------------------------------------------
	--
	UPDATE T_Dataset_Archive
	SET
		AS_state_ID = @archiveState, 
		AS_purge_holdoff_date = DATEADD(dd, @purgeHoldoffInterval, GETDATE())
	WHERE  (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update archive operation failed'
		set @myError = 99
		rollback transaction @transName
		goto done
	end

	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--

Done:
	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetRestoreTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetRestoreTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetRestoreTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetRestoreTaskComplete] TO [PNL\D3M580] AS [dbo]
GO
