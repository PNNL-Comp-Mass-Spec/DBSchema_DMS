/****** Object:  StoredProcedure [dbo].[AddNewInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddNewInstrument
/****************************************************
**
**	Desc: Adds new instrument to database
**        and new storage paths to storage table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**		07/24/2001 -- Added Archive Path setup
**		03/12/2003 -- Modified to call AddUpdateStorage: 
**		11/06/2003 -- Modified to handle new ID for archive path independent of instrument id
**		01/30/2004 -- Modified to return message (grk)
**		02/24/2004 -- Fixed problem inserting first entry into empty tables
**		07/01/2004 -- Modified the function to add records to T_Archive_Path table 
**		12/14/2005 -- Added check for existing instrument
**		04/07/2006 -- Got ride of CDBurn stuff
**		06/28/2006 -- Added support for Usage and Operations Role fields
**		12/11/2008 grk -- Fixed problem with NULL @Usage
**		12/14/2008 grk -- Fixed problem with select result being inadvertently returned
**		01/05/2009 grk -- added @archiveNetworkSharePath (http://prismtrac.pnl.gov/trac/ticket/709)
**		01/05/2010 grk -- added @allowedDatasetTypes (http://prismtrac.pnl.gov/trac/ticket/752)
**		02/12/2010 mem -- Now calling UpdateInstrumentAllowedDatasetType for each dataset type in @allowedDatasetTypes
**		05/25/2010 dac -- Updated archive paths for switch from nwfs to aurora
**    
*****************************************************/
(
	@iName varchar(24),				-- name of new instrument
	@iClass varchar(32),				-- class of " "
	@iMethod varchar(10),				-- capture method of " "
	@iRoomNum varchar(50),				-- where new instrument is located
	@iDescription varchar(50),			-- description of " "

	@sourceMachineName varchar(128),		-- node where import directory lives
	@sourcePath varchar(255),			-- import directory
	@spPath varchar(255),				-- storage path on main DMS server
	@spVolClient  varchar(128),			-- DMS main server name (UNC)
	@spVolServer  varchar(128),			-- DMS main server name (local to server itself)
	@archivePath varchar(50),			-- storage path on SDM archive
	@archiveServer varchar(50),			-- archive server name
	@archiveNote varchar(50),			-- note describing archive path 
	@Usage varchar(50),
	@OperationsRole varchar(50),
							--	(typically common name of instrument as convience)
	@allowedDatasetTypes VARCHAR(2048),
	@message varchar(512) output
)
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @result int

	declare @spSourcePathID int
	declare @spStoragePathID int
	set @spSourcePathID = 2 -- valid reference to 'na' storage path for initial entry
	set @spStoragePathID = 2 -- valid reference to 'na' storage path for initial entry


	---------------------------------------------------
	-- Make sure instrument is not already in instrument table
	---------------------------------------------------
	--
	declare @hit int
	set @hit = -1
	--
	SELECT @hit = Instrument_ID 
	FROM T_Instrument_Name 
	WHERE IN_name = @iName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to look for existing instrument'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	if @myRowCount <> 0
	begin
		set @message = 'Instrument name already in use'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'AddNewInstrument'
	begin transaction @transName

	---------------------------------------------------
	-- Add new instrument ot instrument table
	---------------------------------------------------

	-- get new instrument ID
	--
	declare @iID int
	SELECT @iID = isnull(MAX(Instrument_ID), 0) + 1 FROM T_Instrument_Name

	-- make entry into instrument table
	--
	INSERT INTO T_Instrument_Name(
		IN_name, 
		Instrument_ID, 
		IN_class, 
		IN_source_path_ID, 
		IN_storage_path_ID, 
		IN_capture_method, 
		IN_Room_Number, 
		IN_Description,
		IN_usage, 
		IN_operations_role
	) VALUES (
		@iName, 
		@iID, 
		@iClass, 
		@spSourcePathID, 
		@spStoragePathID, 
		@iMethod, 
		@iRoomNum, 
		@iDescription,
		isnull(@Usage, ''),
		@OperationsRole
	)
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Insert into x table was unsuccessful for add instrument',
			10, 1)
		return 51131
	end
	 
	---------------------------------------------------
	-- make new raw storage directory in storage table
	---------------------------------------------------
	--
	exec @result = AddUpdateStorage
			@spPath, 
			@spVolClient,

			@spVolServer,
			'raw-storage',
			@iName,
			'(na)',
			@spStoragePathID output,
			'add',
			@message output

	--
	if @result <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Creating storage path was unsuccessful for add instrument',
			10, 1)
		return 51132
	end

	---------------------------------------------------
	-- make new transfer directory in storage table
	---------------------------------------------------
	--
	exec @result = AddUpdateStorage
			@sourcePath, 
			'(na)',
			@sourceMachineName,
			'inbox',
			@iName,
			'(na)',
			@spSourcePathID output,
			'add',
			@message output

	--
	if @result <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Creating source path was unsuccessful for add instrument',
			10, 1)
		return 51133
	end

	---------------------------------------------------
	-- add new archive storage path for new instrument
	---------------------------------------------------
	--
	--
	---------------------------------------------------
	-- Derive shared path name
	---------------------------------------------------
	--
	declare @archiveNetworkSharePath varchar(64)
	set @archiveNetworkSharePath = '\' + REPLACE(REPLACE(@archivePath, 'archive', 'a2.emsl.pnl.gov'), '/', '\')
	--
	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------
	-- get new archive ID
	--
	declare @aID int
	--
--	SELECT @aID = isnull(MAX(AP_path_ID), 0) + 1 FROM T_Archive_Path
	--
	-- insert new archive path
	--
	INSERT INTO T_Archive_Path (
		AP_instrument_name_ID,
		AP_archive_path,
		AP_network_share_path,
		Note,
		AP_Server_Name,
		AP_Function
	) VALUES (
		@iID,
		@archivePath,
		@archiveNetworkSharePath,
		@archiveNote,
		@archiveServer,
		'Active'
	)
	--
  
	-- return Archive ID of newly created archive
	--
	set @aID = IDENT_CURRENT('T_Archive_Path')

	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Insert into archive path table was unsuccessful for add instrument',
			10, 1)
		return 51134
	end


	---------------------------------------------------
	-- Call UpdateInstrumentAllowedDatasetType for each entry in @allowedDatasetTypes
	---------------------------------------------------
	
	CREATE TABLE #Tmp_AllowedDatasetTypes (
		DatasetTypeName varchar(128)
	)	

	INSERT INTO #Tmp_AllowedDatasetTypes( DatasetTypeName )
	SELECT DISTINCT Value
	FROM dbo.udfParseDelimitedList ( @allowedDatasetTypes, ',' )
	WHERE IsNull(Value, '') <> ''
	ORDER BY Value
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	Declare @DatasetType varchar(128)
	Declare @continue tinyint

	Set @continue = 1
	While @continue = 1	
	Begin
		SELECT TOP 1 @DatasetType = DatasetTypeName
		FROM #Tmp_AllowedDatasetTypes
		ORDER BY DatasetTypeName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @continue = 0
		Else
		Begin
			EXEC @myError = UpdateInstrumentAllowedDatasetType @iName, @DatasetType, '', 'add', @message output, ''
			
			if @myError <> 0
			begin			
				rollback transaction @transName
				
				Set @message = 'Error associating dataset type "' + @DatasetType + '" with instrument: ' + IsNull(@message, '??')
				
				RAISERROR (@message, 10, 1)
				return 51135
			end

			DELETE FROM #Tmp_AllowedDatasetTypes
			WHERE DatasetTypeName = @DatasetType
			
		End		
	End
	
	---------------------------------------------------
	-- Finalize the transaction
	---------------------------------------------------
	--
	commit transaction @transName
	
	return 0

GO
GRANT EXECUTE ON [dbo].[AddNewInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewInstrument] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewInstrument] TO [PNL\D3M580] AS [dbo]
GO
