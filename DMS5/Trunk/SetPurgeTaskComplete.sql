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
**			01/26/2011 grk - modified actions for @completionCode = 2 to bump holdoff and call broker
**			01/28/2011 mem - Changed holdoff bump from 12 to 24 hours when @completionCode = 2
**			02/01/2011 mem - Added support for @completionCode 3
**			09/02/2011 mem - Now updating AJ_Purged for jobs associated with this dataset
**						   - Now calling PostUsageLogEntry
**			01/27/2012 mem - Now bumping AS_purge_holdoff_date by 90 minutes when @completionCode = 3
**			04/17/2012 mem - Added support for @completionCode = 4 (drive missing)
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0,	-- 0 = success, 1 = Purge Failed, 2 = Archive Update required, 3 = Stage MD5 file required, 4 = Drive Missing
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

Code 3 (Stage MD5 file required) --> 
	Set T_Dataset_Archive.AS_state_ID to 3 (Complete).
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
	Set AS_StageMD5_Required to 1
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
		EXEC S_MakeNewArchiveUpdateJob @datasetNum, '', 1, 0, @message output
		goto SetStates
	end

	-- (MD5 results file is missing; need to have stageMD5 file created by the DatasetPurgeArchiveHelper)
	if @completionCode = 3
	begin
		set @completionState = 3    -- complete
		goto SetStates
	end

	-- (Drive Missing)
	if @completionCode = 4
	begin
		set @message = 'Drive not found for dataset ' + @datasetNum
		Exec PostLogEntry 'Error', @message, 'SetPurgeTaskComplete'
		set @message = ''
		
		set @completionState = 3    -- complete
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
		AS_update_state_ID = @currentUpdateState,
		AS_purge_holdoff_date = CASE WHEN @currentUpdateState = 2    THEN DATEADD(HOUR, 24, GETDATE()) 
		                             WHEN @completionCode IN (2,3,4) THEN DATEADD(MINUTE, 90, GETDATE()) 
		                             ELSE AS_purge_holdoff_date 
		                        END, 
		AS_StageMD5_Required = CASE WHEN @completionCode = 3      THEN 1
		                            ELSE AS_StageMD5_Required
		                        END
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
		
		-- Also update AJ_Purged in T_Analysis_Job
		UPDATE T_Analysis_Job
		SET AJ_Purged = 1
		WHERE AJ_datasetID = @datasetID AND AJ_Purged = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Dataset: ' + @datasetNum
	Exec PostUsageLogEntry 'SetPurgeTaskComplete', @UsageMessage

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
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [svc-dms] AS [dbo]
GO
