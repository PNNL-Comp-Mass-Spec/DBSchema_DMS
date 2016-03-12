/****** Object:  StoredProcedure [dbo].[DoArchiveOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DoArchiveOperation
/****************************************************
**
**	Desc: 
**		Perform archive operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	10/06/2004
**			04/17/2006 grk - added stuf for set archive update 
**			03/27/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@mode varchar(12),
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	
	declare @result int

	---------------------------------------------------
	-- get datasetID and archive state
	---------------------------------------------------
	declare @datasetID int
	declare @ArchiveStateID int
	declare @NewState int

	set @datasetID = 0
	
	SELECT     
		@datasetID = T_Dataset.Dataset_ID, 
		@ArchiveStateID = T_Dataset_Archive.AS_state_ID
	FROM 
		T_Dataset INNER JOIN
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @datasetID = 0
	begin
		set @msg = 'Could not get Id or archive state for dataset "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Reset state of failed archive dataset to 'new' 
	---------------------------------------------------

	if @mode = 'archivereset'
	begin
		-- if archive not in failed state, can't reset it
		--
		if @ArchiveStateID not in (6, 2) -- "Operation Failed" or "Archive In Progress"
		begin
			set @msg = 'Archive state for dataset "' + @datasetNum + '" not in proper state to be reset'
			RAISERROR (@msg, 10, 1)
			return 51693
		end

		-- Reset the Archive task to state "new"
		Set @NewState = 1
		
		-- Update archive state of dataset to new
		--
		UPDATE T_Dataset_Archive 
		SET AS_state_ID = @NewState
		WHERE (AS_Dataset_ID  = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset archive table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51694
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 6, @datasetID, @NewState, @callingUser

		return 0
	end -- mode 'reset_archive'


	---------------------------------------------------
	-- Reset state of failed archive dataset to 'Update Required' 
	---------------------------------------------------

	if @mode = 'update_req'
	begin
		-- Change the Archive Update state to "Update Required"		
		Set @NewState = 2
		
		-- Update archive update state of dataset
		--
		UPDATE T_Dataset_Archive 
		SET AS_update_state_ID = @NewState
		WHERE (AS_Dataset_ID  = @datasetID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update was unsuccessful for dataset archive table "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51695
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 7, @datasetID, @NewState, @callingUser

		return 0
	end -- mode 'update_req'
	
	---------------------------------------------------
	-- Operation for mode ???
	---------------------------------------------------

	if @mode = '???'
	begin
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert operation failed'
			RAISERROR (@msg, 10, 1)
			return 51211
		end

		return 0
	end -- mode '???'
	
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @msg = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@msg, 10, 1)
	return 51222

GO
GRANT EXECUTE ON [dbo].[DoArchiveOperation] TO [DMS_Archive_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoArchiveOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoArchiveOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoArchiveOperation] TO [PNL\D3M578] AS [dbo]
GO
