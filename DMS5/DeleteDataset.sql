/****** Object:  StoredProcedure [dbo].[DeleteDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteDataset
/****************************************************
**
**	Desc: Deletes given dataset from the dataset table
**        and all referencing tables
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	01/26/2001
**			03/01/2004 grk - added unconsume scheduled run
**			04/07/2006 grk - got rid of dataset list stuff
**			04/07/2006 grk - Got rid of CDBurn stuff
**			05/01/2007 grk - Modified to call modified UnconsumeScheduledRun (Ticket #446)
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			05/08/2009 mem - Now checking T_Dataset_Info
**			12/13/2011 mem - Now passing @callingUser to UnconsumeScheduledRun
**						   - Now checking T_Dataset_QC and T_Dataset_ScanTypes
**			02/19/2013 mem - No longer allowing deletion if analysis jobs exist
**			02/21/2013 mem - Updated call to UnconsumeScheduledRun to refer to @retainHistory by name
**			05/08/2013 mem - No longer passing @wellplateNum and @wellNum to UnconsumeScheduledRun
**			08/31/2016 mem - Delete failed capture jobs for the dataset
**			10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**    
*****************************************************/
(
	@datasetNum varchar(128),
    @message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	declare @msg varchar(256)

	declare @datasetID int
	declare @state int
	
	declare @result int

	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @datasetNum = IsNull(@datasetNum, '')
	Set @message = ''

	If @datasetNum = ''
	Begin
		set @msg = '@datasetNum parameter is blank; nothing to delete'
		RAISERROR (@msg, 10, 1)
		return 51139
	End
	
	---------------------------------------------------
	-- Get the datasetID and current state
	---------------------------------------------------
	--
	set @datasetID = 0
	--
	SELECT  
		@state = DS_state_ID,
		@datasetID = Dataset_ID		
	FROM T_Dataset 
	WHERE (Dataset_Num = @datasetNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError <> 0
	begin
		set @msg = 'Could not get Id or state for dataset "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end
	--
	if @datasetID = 0
	begin
		set @msg = 'Dataset does not exist "' + @datasetNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51141
	end

	If Exists (SELECT * FROM T_Analysis_Job WHERE AJ_datasetID = @datasetID)
	Begin
		set @msg = 'Cannot delete a dataset with existing analysis jobs'
		RAISERROR (@msg, 10, 1)
		return 51142
	End
	
	---------------------------------------------------
	-- Start a transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteDataset'
	begin transaction @transName

	---------------------------------------------------
	-- Delete any entries for the dataset from the archive table
	---------------------------------------------------
	--
	DELETE FROM T_Dataset_Archive 
	WHERE AS_Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from archive table was unsuccessful for dataset', 10, 1)
		return 51131
	end
	
	---------------------------------------------------
	-- Delete any auxiliary info associated with dataset
	---------------------------------------------------
	--	
	exec @result = DeleteAuxInfo 'Dataset', @datasetNum, @message output

	if @result <> 0
	begin
		rollback transaction @transName
		set @msg = 'Delete auxiliary information was unsuccessful for dataset: ' + @message
		RAISERROR (@msg, 10, 1)
		return 51136
	end

	---------------------------------------------------
	-- Restore any consumed requested runs
	---------------------------------------------------
	--
	exec @result = UnconsumeScheduledRun @datasetNum, @retainHistory=0, @message=@message output, @callingUser=@callingUser
	if @result <> 0
	begin
		rollback transaction @transName
		set @msg = 'Unconsume operation was unsuccessful for dataset: ' + @message
		RAISERROR (@msg, 10, 1)
		return 51103
	end
	
	---------------------------------------------------
	-- Delete any entries in T_Dataset_Info
	---------------------------------------------------
	--
	DELETE FROM T_Dataset_Info
	WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from Dataset Info table was unsuccessful for dataset', 10, 1)
		return 51132
	end
	
	---------------------------------------------------
	-- Delete any entries in T_Dataset_QC
	---------------------------------------------------
	--
	DELETE FROM T_Dataset_QC
	WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from Dataset QC table was unsuccessful for dataset', 10, 1)
		return 51133
	end
	
	---------------------------------------------------
	-- Delete any entries in T_Dataset_ScanTypes
	---------------------------------------------------
	--
	DELETE FROM T_Dataset_ScanTypes
	WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from Dataset ScanTypes table was unsuccessful for dataset', 10, 1)
		return 51134
	end

	---------------------------------------------------
	-- Delete any failed jobs in the DMS_Capture database
	---------------------------------------------------
	--
	DELETE FROM DMS_Capture.dbo.T_Jobs
	WHERE Dataset = @datasetNum AND State = 5
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from DMS_Capture.dbo.T_Jobs was unsuccessful for dataset', 10, 1)
		return 51135
	end

	---------------------------------------------------
	-- Update log entries in the DMS_Capture database
	---------------------------------------------------
	--
	UPDATE DMS_Capture.dbo.T_Log_Entries
	SET [Type] = 'ErrorAutoFixed'
	WHERE ([Type] = 'error') AND
	      message LIKE '%' + @datasetNum + '%'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from DMS_Capture.dbo.T_Jobs was unsuccessful for dataset', 10, 1)
		return 51136
	end


	---------------------------------------------------
	-- Delete entry from dataset table
	---------------------------------------------------
	--
    DELETE FROM T_Dataset
    WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Delete from dataset table was unsuccessful for dataset (RowCount != 1)',
			10, 1)
		return 51137
	end
	
	-- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0

		Exec AlterEventLogEntryUser 4, @datasetID, @stateID, @callingUser
	End

	commit transaction @transName
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataset] TO [Limited_Table_Write] AS [dbo]
GO
