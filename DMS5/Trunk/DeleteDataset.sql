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
**			04/07/2006 grk - Got ride of CDBurn stuff
**			05/01/2007 grk - Modified to call modified UnconsumeScheduledRun (Ticket #446)
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			05/08/2009 mem - Now checking T_Dataset_Info
**    
*****************************************************/
(
	@datasetNum varchar(128),
    @message varchar(512) output,
	@callingUser varchar(128) = ''
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
	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- get datasetID and current state
	---------------------------------------------------
	declare @wellplateNum varchar(50)
	declare @wellNum varchar(50)

	set @datasetID = 0
	--
	SELECT  
		@state = DS_state_ID,
		@datasetID = Dataset_ID,
		@wellplateNum = DS_wellplate_num, 
		@wellNum = DS_well_num
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
	--
	if @datasetID = 0
	begin
		set @message = 'Datset does not exist"' + @datasetNum + '"'
		return 51141
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteDataset'
	begin transaction @transName
--	print 'start transaction' -- debug only

	---------------------------------------------------
	-- delete any entries for the dataset from the archive table
	---------------------------------------------------

	DELETE FROM T_Dataset_Archive 
	WHERE (AS_Dataset_ID = @datasetID)
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from archive table was unsuccessful for dataset', 10, 1)
		return 51131
	end

	---------------------------------------------------
	-- delete any entries for the dataset from the analysis job table
	---------------------------------------------------

	DELETE FROM T_Analysis_Job 
	WHERE (AJ_datasetID = @datasetID)	
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from analysis job table was unsuccessful for dataset', 10, 1)
		return 51132
	end
	
	---------------------------------------------------
	-- delete any auxiliary info associated with dataset
	---------------------------------------------------
		
	exec @result = DeleteAuxInfo 'Dataset', @datasetNum, @message output

	if @result <> 0
	begin
		rollback transaction @transName
		set @msg = 'Delete auxiliary information was unsuccessful for dataset: ' + @message
		RAISERROR (@msg, 10, 1)
		return 51136
	end

	---------------------------------------------------
	-- restore any consumed requested runs
	---------------------------------------------------

	exec @result = UnconsumeScheduledRun @datasetNum, @wellplateNum, @wellNum, 0, @message output
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
	DELETE FROM T_Dataset_Info
	WHERE Dataset_ID = @datasetID
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from dataset info table was unsuccessful for dataset', 10, 1)
		return 51132
	end
		
	---------------------------------------------------
	-- delete entry from dataset table
	---------------------------------------------------

    DELETE FROM T_Dataset
    WHERE Dataset_ID = @datasetID

	if @@rowcount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Delete from dataset table was unsuccessful for dataset',
			10, 1)
		return 51136
	end

	-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0

		Exec AlterEventLogEntryUser 4, @datasetID, @stateID, @callingUser
	End

	commit transaction @transName
	
	return 0

GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteDataset] TO [PNL\D3M580] AS [dbo]
GO
