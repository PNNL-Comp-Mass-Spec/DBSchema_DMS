/****** Object:  StoredProcedure [dbo].[AddArchiveDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddArchiveDataset
/****************************************************
**
**	Desc: Make new entry into the archive table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: @datasetID  new entry references this
**                          dataset
**	
**
**	Auth:	grk
**	Date:	01/26/2001
**			04/04/2006 grk - Added setting holdoff interval
**			01/14/2010 grk - Assign storage path on creation of archive entry
**			01/22/2010 grk - Existing entry in archive table prevents duplicate, but doesn't raise error
**			05/11/2011 mem - Now calling GetInstrumentArchivePathForNewDatasets to determine @archivePathID
**			05/12/2011 mem - Now passing @DatasetID and @AutoSwitchActiveArchive to GetInstrumentArchivePathForNewDatasets
**			06/01/2012 mem - Bumped up @holdOffHours to 2 weeks
**			06/12/2012 mem - Now looking up the Purge_Policy in T_Instrument_Name
**
*****************************************************/
(
	@datasetID int
)
As
	declare @holdOffHours int
	set @holdOffHours = 336			-- 2 weeks
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	DECLARE @message VARCHAR(512)
	SET @message = ''
	
   	---------------------------------------------------
	-- don't allow duplicate dataset IDs in table
	---------------------------------------------------
	--
	If Exists (SELECT * FROM T_Dataset_Archive WHERE (AS_Dataset_ID = @datasetID))
	begin
		-- Dataset already in archive table
		return 0
	end

	---------------------------------------------------
	-- Lookup the Instrument ID
	---------------------------------------------------
	
	declare @instrumentID int = 0
	--
	SELECT @instrumentID = DS_instrument_name_ID
	FROM T_Dataset
	WHERE Dataset_ID = @DatasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up dataset info'
		RAISERROR (@message, 10, 1)
	end
	--
	if @instrumentID = 0
	begin
		set @message = 'Dataset ID ' + Convert(varchar(12), @DatasetID) + ' not found in T_Dataset'
		RAISERROR (@message, 10, 1)
	end
		
   	---------------------------------------------------
	-- Get the assigned archive path
	---------------------------------------------------
	--
	declare @archivePathID int
	set @archivePathID = 0
	--
	exec @archivePathID = GetInstrumentArchivePathForNewDatasets @instrumentID, @DatasetID, @AutoSwitchActiveArchive=1, @infoOnly=0
	--
	if @archivePathID = 0
	begin
		set @message = 'GetInstrumentArchivePathForNewDatasets returned zero for an archive path ID for dataset ' + Convert(varchar(12), @DatasetID)
		RAISERROR (@message, 10, 1)
		return @myError
	end
	
	---------------------------------------------------
	-- Lookup the purge policy for this instrument
	---------------------------------------------------
	declare @PurgePolicy tinyint = 0
	
	SELECT @PurgePolicy = Default_Purge_Policy
	FROM T_Instrument_Name
	WHERE Instrument_ID = @instrumentID
	
	Set @PurgePolicy = IsNull(@PurgePolicy, 0)
	
	
   	---------------------------------------------------
	-- make entry into archive table
	---------------------------------------------------
	--
	INSERT INTO T_Dataset_Archive
		( AS_Dataset_ID,
		  AS_state_ID,
		  AS_update_state_ID,
		  AS_storage_path_ID,
		  AS_datetime,
		  AS_purge_holdoff_date,
		  Purge_Policy
		)
	VALUES
		( @datasetID,
		  1,
		  1,
		  @archivePathID,
		  GETDATE(),
		  DATEADD(Hour, @holdOffHours, GETDATE()),
		  @PurgePolicy
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	if @myRowCount <> 1
	begin
		RAISERROR ('Update was unsuccessful for archive table', 10, 1)
		return 51100
	end

	return

GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchiveDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddArchiveDataset] TO [PNL\D3M580] AS [dbo]
GO
