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
**			06/12/2012 mem - Added support for @completionCode = 5 and @completionCode = 6  (corresponding to Archive States 14 and 15)
**			06/15/2012 mem - No longer changing the purge holdoff date if @completionCode = 4 (drive missing)
**			08/13/2013 mem - Now using explicit parameter names when calling S_MakeNewArchiveUpdateJob
**			08/15/2013 mem - Added support for @completionCode = 7 (dataset folder missing in archive)
**			08/26/2013 mem - Now mentioning "permissions error" when @completionCode = 7
**			03/21/2014 mem - Tweaked log message for @completionCode = 7
**			07/05/2016 mem - Added support for @completionCode = 8 (Aurora is offline)
**						   - Archive path is now aurora.emsl.pnl.gov
**			09/02/2016 mem - Archive path is now adms.emsl.pnl.gov
**			11/09/2016 mem - Include the storage server name when calling PostLogEntry
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0,	-- 0 = success, 1 = Purge Failed, 2 = Archive Update required, 3 = Stage MD5 file required, 4 = Drive Missing, 5 = Purged Instrument Data (and any other auto-purge items), 6 = Purged all data except QC folder, 7 = Dataset folder missing in archive, 8 = Archive offline
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @datasetID int
	declare @storageServerName varchar(64)
	declare @datasetState int
	declare @completionState int
 	declare @result int
	declare @instrumentClass varchar(32)
		
	---------------------------------------------------
	-- Resolve dataset into ID
	-- Also determine the storage server name
	---------------------------------------------------
	--
	SELECT @datasetID = DS.Dataset_ID,
	       @storageServerName = SPath.SP_machine_name
	FROM T_Dataset DS
	     LEFT OUTER JOIN T_Storage_Path SPath
	       ON DS.DS_storage_path_ID = SPath.SP_path_ID
	WHERE (DS.Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset ID for dataset ' + @datasetNum
		goto done
	end

	---------------------------------------------------
	-- Determine current "Archive" state and current "ArchiveUpdate" state
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
Code 0 (success) 
	Set T_Dataset_Archive.AS_state_ID to 4 (Purged). 
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.

Code 1 (failed)
	Set T_Dataset_Archive.AS_state_ID to 8 (Failed). 
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.

Code 2 (update reqd)
	Set T_Dataset_Archive.AS_state_ID to 3 (Complete). 
	Set T_Dataset_Archive.AS_update_state_ID to 2 (Update Required)
	Bump up Purge Holdoff Date by 90 minutes

Code 3 (Stage MD5 file required)
	Set T_Dataset_Archive.AS_state_ID to 3 (Complete).
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
	Set AS_StageMD5_Required to 1
	Bump up Purge Holdoff Date by 90 minutes
	
Code 4 (Drive Missing)
	Set T_Dataset_Archive.AS_state_ID to 3 (Complete).
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
	Leave Purge Holdoff Date unchanged

Code 5 (Purged Instrument Data and any other auto-purge items)
	Set T_Dataset_Archive.AS_state_ID to 14
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.

Code 6 (Purged all data except QC folder)
	Set T_Dataset_Archive.AS_state_ID to 15
	Leave T_Dataset_Archive.AS_update_state_ID unchanged.
	
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
		EXEC S_MakeNewArchiveUpdateJob @datasetNum, @ResultsFolderName='', @AllowBlankResultsFolder=1, @PushDatasetToMyEMSL=0, @message=@message output
		goto SetStates
	end

	-- (MD5 results file is missing; need to have stageMD5 file created by the DatasetPurgeArchiveHelper)
	if @completionCode = 3
	begin
		set @completionState = 3    -- complete
		goto SetStates
	end

	If IsNull(@storageServerName, '') = ''
		Set @storageServerName = '??'

	Declare @postedBy varchar(128) = 'SetPurgeTaskComplete: ' + @storageServerName
	
	-- (Drive Missing)
	if @completionCode = 4
	begin
		set @message = 'Drive not found for dataset ' + @datasetNum
		Exec PostLogEntry 'Error', @message, @postedBy
		set @message = ''
		
		set @completionState = 3    -- complete
		goto SetStates
	end

	-- (Purged Instrument Data and any other auto-purge items)
	if @completionCode = 5
	begin
		set @completionState = 14    -- complete
		goto SetStates
	end
	
	-- (Purged all data except QC folder)
	if @completionCode = 6
	begin
		set @completionState = 15    -- complete
		goto SetStates
	end

	-- (Dataset folder missing in archive, either in MyEMSL or at \\adms.emsl.pnl.gov\dmsarch)
	if @completionCode = 7
	begin
		set @message = 'Dataset folder not found in archive or in MyEMSL; most likely a MyEMSL timeout, but could be a permissions error; dataset ' + @datasetNum
		Exec PostLogEntry 'Error', @message, @postedBy
		set @message = ''
		
		set @completionState = 3    -- complete
		goto SetStates
	end
	
	-- (Archive is offline (Aurora is offline): \\adms.emsl.pnl.gov\dmsarch)
	if @completionCode = 8
	begin
		set @message = 'Archive is offline; cannot purge dataset ' + @datasetNum
		Exec PostLogEntry 'Error', @message, @postedBy
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
		AS_purge_holdoff_date = CASE WHEN @currentUpdateState = 2    THEN DATEADD(  HOUR, 24, GETDATE()) 
		                             WHEN @completionCode IN (2,3)   THEN DATEADD(MINUTE, 90, GETDATE()) 
		                             WHEN @completionCode = 7        THEN DATEADD(  HOUR, 48, GETDATE()) 
		                             ELSE AS_purge_holdoff_date 
		                        END, 
		AS_StageMD5_Required = CASE WHEN @completionCode = 3         THEN 1
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
	
	If @completionState in (4, 14)
	Begin
		-- Dataset was purged; update AS_instrument_data_purged to be 1
		-- This field is useful because, if an analysis job is run on a purged dataset,
		--  then AS_state_ID will change back to 3=Complete, and we therefore
		--  wouldn't be able to tell if the raw instrument file is available
		-- Note that trigger trig_u_Dataset_Archive will likely have already updated AS_instrument_data_purged
		--
		UPDATE T_Dataset_Archive
		SET AS_instrument_data_purged = 1
		WHERE AS_Dataset_ID = @datasetID AND
		      IsNull(AS_instrument_data_purged, 0) = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	
	If @completionState in (4)
	Begin
		-- Make sure QC_Data_Purged is now 1
		-- Note that trigger trig_u_Dataset_Archive will likely have already updated AS_instrument_data_purged
		--
		UPDATE T_Dataset_Archive
		SET QC_Data_Purged = 1
		WHERE AS_Dataset_ID = @datasetID AND
		      IsNull(QC_Data_Purged, 0) = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
		
	
	If @completionState IN (4, 15)
	Begin
		-- Update AJ_Purged in T_Analysis_Job for all jobs associated with this dataset
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
GRANT EXECUTE ON [dbo].[SetPurgeTaskComplete] TO [DMS_Analysis_Job_Runner] AS [dbo]
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
