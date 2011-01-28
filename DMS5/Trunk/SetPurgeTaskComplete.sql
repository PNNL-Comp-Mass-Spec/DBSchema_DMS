/****** Object:  StoredProcedure [dbo].[SetPurgeTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.SetPurgeTaskComplete
/****************************************************
**
**	Desc: Sets archive state of dataset record given by @datasetNum
**        according to given completion code
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/04/2003
**			02/16/2007 grk - add completion code options and also set archive state (Ticket #131)
**			08/04/2008 mem - Now updating column AS_instrument_data_purged (Ticket #683)
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode <> 0 -> failure
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
	declare @datasetState int
	declare @completionState int
 	declare @result int
	declare @instrumentClass varchar(32)
		
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
	-- check current archive state
	---------------------------------------------------

	declare @currentState as int
	set @currentState = 0
	--
	declare @currentUpdateState as int
	set @currentUpdateState = 0
	--
	SELECT 
		@currentState = AS_state_ID,
		@currentUpdateState = AS_update_state_ID
	FROM T_Dataset_Archive
	WHERE (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get current archive state for dataset ' + @datasetNum
		goto done
	end
	
	if @currentState <> 7
	begin
		set @myError = 1
		set @message = 'Current archive state incorrect for dataset ' + @datasetNum
		goto done
	end

	---------------------------------------------------
	-- choose archive state and archive update  state
	-- based upon completion code
	---------------------------------------------------
/*
Code 0 (success) --> 
	Set T_Dataset_Archive.AS_state_ID to 4 (Purged). 
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
Code 1 (failed) --> 
	Set T_Dataset_Archive.AS_state_ID to 8 (Failed). 
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
Code 2 (update reqd) --> 
	Set T_Dataset_Archive.AS_state_ID to 3 (Complete). 
	Set T_Dataset_Archive.AS_update_state_ID to 2 (Update Required)

*/
	-- (success)
	if @completionCode = 0 
	begin
		set @completionState = 4 -- purged
		goto SetStates
	end

	-- (failed)
	if @completionCode = 1
	begin
		set @completionState = 8 -- purge failed
		goto SetStates
	end

    -- (update reqd)
	if @completionCode = 2
	begin
		set @completionState = 3    -- complete
		set @currentUpdateState = 2 -- Update Required
		goto SetStates
	end

	-- if we got here, completion code was not recognized.  Bummer.
	--
	set @message = 'Completion code was not recognized'
	goto Done

SetStates:
	UPDATE T_Dataset_Archive
	SET
		AS_state_ID = @completionState,
		AS_update_state_ID = @currentUpdateState  
	WHERE  (AS_Dataset_ID = @datasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Update operation failed'
		set @myError = 99
		goto done
	end
	
	if @completionState = 4
	Begin
		-- Dataset was purged; update AS_instrument_data_purged to be 1
		-- This field is useful if an analysis job is run on a purged dataset, since, 
		--  when that happens, AS_state_ID will go back to 3=Complete, and we therefore
		--  wouldn't be able to tell if the raw instrument file is available
		UPDATE T_Dataset_Archive
		SET AS_instrument_data_purged = 1
		WHERE AS_Dataset_ID = @datasetID AND
		      IsNull(AS_instrument_data_purged, 0) = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End

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
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPurgeTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPurgeTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetPurgeTaskComplete] TO [PNL\D3M580] AS [dbo]
GO
