/****** Object:  StoredProcedure [dbo].[DoDatasetOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[DoDatasetOperation]
/****************************************************
**
**	Desc: 
**		Perform dataset operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	04/08/2002
**			08/07/2003 grk - allowed reset from "Not Ready" state
**			05/05/2005 grk - removed default value from mode
**			03/24/2006 grk - added "restore" mode
**			09/15/2006 grk - repair "restore" mode
**			03/27/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			07/15/2008 jds - Added "delete_all" mode (Ticket #644) - deletes a dataset with any restrictions
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@mode varchar(12),					-- 'delete', 'reset', 'store'; legacy version supported 'burn'
    @message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	declare @datasetID int
	set @datasetID = 0
	
	declare @CurrentState int
	declare @NewState int
	
	declare @result int

	---------------------------------------------------
	-- get datasetID and current state
	---------------------------------------------------

	SELECT  
		@CurrentState = DS_state_ID,
		@datasetID = Dataset_ID 
	FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not get Id or state for dataset "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Delete dataset if it is in "new" state only
	---------------------------------------------------

	if @mode = 'delete_all'
	begin

		---------------------------------------------------
		-- delete the dataset
		---------------------------------------------------

		execute @result = DeleteDataset @datasetNum, @message output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR ('Could not delete dataset "%s"',
				10, 1, @datasetNum)
			return 51142
		end

		return 0
	end

	---------------------------------------------------
	-- Delete dataset if it is in "new" state only
	---------------------------------------------------

	if @mode = 'delete'
	begin

		---------------------------------------------------
		-- verify that dataset is still in 'new' state
		---------------------------------------------------

		if @CurrentState <> 1
		begin
			set @msg = 'Dataset "' + @datasetNum + '" must be in "new" state to be deleted by user'
			RAISERROR (@msg, 10, 1)
			return 51141
		end
		
		---------------------------------------------------
		-- delete the dataset
		---------------------------------------------------

		execute @result = DeleteDataset @datasetNum, @message output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR ('Could not delete dataset "%s"',
				10, 1, @datasetNum)
			return 51142
		end

		return 0
	end -- mode 'deleteNew'
	
	---------------------------------------------------
	-- Reset state of failed dataset to 'new' 
	---------------------------------------------------

	if @mode = 'reset'
	begin

		-- if dataset not in failed state, can't reset it
		--
		if @CurrentState not in (5, 9) -- "Not ready" or "Failed"
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be reset if capture not in failed or in not ready state ' + cast(@CurrentState as varchar(12))
			RAISERROR (@msg, 10, 1)
			return 51693
		end

		-- Update state of dataset to new
		--
		Set @NewState = 1		 -- "new' state

		UPDATE T_Dataset 
		SET DS_state_ID = @NewState
		WHERE (Dataset_ID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51694
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 4, @datasetID, @NewState, @callingUser

		return 0
	end -- mode 'reset'
	
	---------------------------------------------------
	-- set state of dataset to "Restore Requested"
	---------------------------------------------------

	if @mode = 'restore'
	begin

		-- if dataset not in complete state, can't request restore
		--
		if @CurrentState <> 3
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be restored unless it is in completed state'
			RAISERROR (@msg, 10, 1)
			return 51693
		end

		-- if dataset not in purged archive state, can't request restore
		--
		declare @as int
		set @as = 0
		--
		SELECT 
			@as = T_Dataset_Archive.AS_state_ID
		FROM 
			T_Dataset_Archive INNER JOIN
			T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
		WHERE
			 T_Dataset.Dataset_ID = @datasetID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to check archive state'
			RAISERROR (@msg, 10, 1)
			return 51692
		end
		--
		if @as <> 4
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be restored unless it is purged state'
			return 51690
		end

		-- Update state of dataset to "Restore Requested"
		--
		Set @NewState = 10		-- "restore required" state
		
		UPDATE T_Dataset 
		SET DS_state_ID = @NewState 
		WHERE (Dataset_ID = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51694
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 4, @datasetID, @NewState, @callingUser

		return 0
	end -- mode 'restore'	

	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @msg = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@msg, 10, 1)
	return 51222


GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS_DS_Entry]
GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS2_SP_User]
GO
