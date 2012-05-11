/****** Object:  StoredProcedure [dbo].[DoDatasetOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoDatasetOperation
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
**			08/19/2010 grk - try-catch for error handling
**			05/25/2011 mem - Fixed bug that reported "mode was unrecognized" for valid modes
**						   - Removed 'restore' mode
**			01/12/2012 mem - Now preventing deletion if @mode is 'delete' and the dataset exists in S_V_Capture_Jobs_ActiveOrComplete
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@mode varchar(12),					-- 'delete', 'delete_all', 'reset'; legacy version supported 'burn'
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
	declare @ValidMode tinyint = 0
	
	BEGIN TRY 

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
		RAISERROR (@msg, 11, 1)
	end

	---------------------------------------------------
	-- Delete dataset regardless of state
	---------------------------------------------------
	--
	if @mode = 'delete_all'
	begin

		execute @result = DeleteDataset @datasetNum, @message output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR ('Could not delete dataset "%s"', 11, 2, @datasetNum)
		end
		
		set @ValidMode = 1
	end

	---------------------------------------------------
	-- Delete dataset if it is in "new" state only
	---------------------------------------------------
	--
	if @mode = 'delete'
	begin

		---------------------------------------------------
		-- verify that dataset is still in 'new' state
		---------------------------------------------------

		if @CurrentState <> 1
		begin
			set @msg = 'Dataset "' + @datasetNum + '" must be in "new" state to be deleted by user'
			RAISERROR (@msg, 11, 3)
		end
		
		---------------------------------------------------
		-- Verify that the dataset does not have an active or completed capture job
		---------------------------------------------------

		If Exists (SELECT * FROM S_V_Capture_Jobs_ActiveOrComplete WHERE Dataset_ID = @datasetID And State <= 2)
		begin
			set @msg = 'Dataset "' + @datasetNum + '" is being processed by the DMS_Capture database; unable to delete'
			RAISERROR (@msg, 11, 3)
		end		

		If Exists (SELECT * FROM S_V_Capture_Jobs_ActiveOrComplete WHERE Dataset_ID = @datasetID And State > 2)
		begin
			set @msg = 'Dataset "' + @datasetNum + '" has been processed by the DMS_Capture database; unable to delete'
			RAISERROR (@msg, 11, 3)
		end		
		
		
		---------------------------------------------------
		-- delete the dataset
		---------------------------------------------------

		execute @result = DeleteDataset @datasetNum, @message output, @callingUser
		--
		if @result <> 0
		begin
			RAISERROR ('Could not delete dataset "%s"', 11, 4, @datasetNum)
		end
		
		set @ValidMode = 1
	end -- mode 'delete'
	
	---------------------------------------------------
	-- Reset state of failed dataset to 'new' 
	---------------------------------------------------
	--
	if @mode = 'reset'
	begin

		-- if dataset not in failed state, can't reset it
		--
		if @CurrentState not in (5, 9) -- "Failed" or "Not ready"
		begin
			set @msg = 'Dataset "' + @datasetNum + '" cannot be reset if capture not in failed or in not ready state ' + cast(@CurrentState as varchar(12))
			RAISERROR (@msg, 11, 5)
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
			RAISERROR (@msg, 11, 6)
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 4, @datasetID, @NewState, @callingUser

		set @ValidMode = 1
	end -- mode 'reset'
	
	
	if @ValidMode = 0
	begin
		---------------------------------------------------
		-- Mode was unrecognized
		---------------------------------------------------
		
		set @msg = 'Mode "' + @mode +  '" was unrecognized'
		RAISERROR (@msg, 11, 10)
	end
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetOperation] TO [PNL\D3M580] AS [dbo]
GO
