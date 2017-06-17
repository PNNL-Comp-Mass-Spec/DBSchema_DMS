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
**			11/14/2013 mem - Now preventing reset if the first step of dataset capture succeeded
**			02/23/2016 mem - Add set XACT_ABORT on
**			01/10/2017 mem - Add @mode 'createjobs' which adds the dataset to T_Predefined_Analysis_Scheduling_Queue so that default jobs will be created 
**			                 (duplicate jobs are not created)
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			05/04/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@mode varchar(12),					-- 'delete', 'delete_all', 'reset', 'createjobs'; legacy version supported 'burn'
    @message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	set @message = ''
	
	Declare @msg varchar(256)

	Declare @datasetID int
	set @datasetID = 0
	
	Declare @CurrentState int
	Declare @NewState int
	
	Declare @result int
	Declare @ValidMode tinyint = 0
	Declare @logErrors tinyint = 0
	
	BEGIN TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DoDatasetOperation', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

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

	Set @logErrors = 1
	
	---------------------------------------------------
	-- Schedule the dataset for predefined job processing
	---------------------------------------------------
	--
	if @mode = 'createjobs'
	begin
		If IsNull(@callingUser, '') = ''
			Set @callingUser = SUSER_SNAME()

		If Exists (SELECT * FROM T_Predefined_Analysis_Scheduling_Queue WHERE Dataset_ID = @datasetID AND State = 'New')
		Begin
			Declare @enteredMax datetime
			
			SELECT @enteredMax = Max(Entered) 
			FROM T_Predefined_Analysis_Scheduling_Queue 
			WHERE Dataset_ID = @datasetID AND State = 'New'
			
			Declare @elapsedHours float = DateDiff(minute, IsNull(@enteredMax, GetDate()), GetDate()) / 60.0
			
			Set @logErrors = 0
			
			If @elapsedHours >= 0.5
			Begin
				-- Round @elapsedHours to one digit, then convert to a string
				Declare @elapsedHoursText varchar(9) = Cast(Cast(Round(@elapsedHours, 1) AS Numeric(12,1)) AS varchar(9))
				RAISERROR ('Default job creation for dataset ID %d has been waiting for %s hours; please contact a DMS administrator to diagnose the delay', 11, 2, @datasetID, @elapsedHoursText)
			End
			Else
			Begin
				RAISERROR ('Dataset ID %d is already scheduled to have default jobs created; please wait at least 5 minutes', 11, 2, @datasetID)
			End
			
		End

		INSERT INTO T_Predefined_Analysis_Scheduling_Queue (Dataset_ID, CallingUser)
		VALUES (@datasetID, @callingUser)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			RAISERROR ('Error adding "%s" to T_Predefined_Analysis_Scheduling_Queue, error code %d', 11, 2, @datasetNum, @myError)
		end
		
		set @ValidMode = 1
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
			Set @logErrors = 0
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
	-- This is used by the "Retry Capture" button on the dataset detail report page
	---------------------------------------------------
	--
	if @mode = 'reset'
	begin

		-- if dataset not in failed state, can't reset it
		--
		if @CurrentState not in (5, 9) -- "Failed" or "Not ready"
		begin
			Set @logErrors = 0
			set @msg = 'Dataset "' + @datasetNum + '" cannot be reset if capture not in failed or in not ready state ' + cast(@CurrentState as varchar(12))
			RAISERROR (@msg, 11, 5)
		end

		-- Do not allow a reset if the dataset succeeded the first step of capture
		If Exists (SELECT * FROM S_V_Capture_Job_Steps WHERE Dataset_ID = @datasetID AND Tool = 'DatasetCapture' AND State IN (4,5))
		begin
			Set @logErrors = 0
			set @msg = 'Dataset "' + @datasetNum + '" cannot be reset because it has already been successfully captured; please contact a system administrator for further assistance'
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
			
		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Dataset ' + @datasetNum
			Exec PostLogEntry 'Error', @logMessage, 'DoDatasetOperation'
		End
	END CATCH
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoDatasetOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoDatasetOperation] TO [Limited_Table_Write] AS [dbo]
GO
