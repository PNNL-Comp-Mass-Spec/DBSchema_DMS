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
**	Auth:	grk
**	Date:	01/26/2001
**			07/24/2001 - Added Archive Path setup
**			03/12/2003 - Modified to call AddUpdateStorage: 
**			11/06/2003 - Modified to handle new ID for archive path independent of instrument id
**			01/30/2004 - Modified to return message (grk)
**			02/24/2004 - Fixed problem inserting first entry into empty tables
**			07/01/2004 - Modified the function to add records to T_Archive_Path table 
**			12/14/2005 - Added check for existing instrument
**			04/07/2006 - Got rid of CDBurn stuff
**			06/28/2006 - Added support for Usage and Operations Role fields
**			12/11/2008 grk - Fixed problem with NULL @Usage
**			12/14/2008 grk - Fixed problem with select result being inadvertently returned
**			01/05/2009 grk - added @archiveNetworkSharePath (http://prismtrac.pnl.gov/trac/ticket/709)
**			01/05/2010 grk - added @allowedDatasetTypes (http://prismtrac.pnl.gov/trac/ticket/752)
**			02/12/2010 mem - Now calling UpdateInstrumentAllowedDatasetType for each dataset type in @allowedDatasetTypes
**			05/25/2010 dac - Updated archive paths for switch from nwfs to aurora
**			08/30/2010 mem - Replaced parameter @allowedDatasetTypes with @InstrumentGroup
**			05/12/2011 mem - Added @AutoDefineStoragePath
**						   - Expanded @archivePath, @archiveServer, and @archiveNote to larger varchar() variables
**			05/13/2011 mem - Now calling ValidateAutoStoragePathParams
**			11/30/2011 mem - Added parameter @PercentEMSLOwned
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**    
*****************************************************/
(
	@iName varchar(24),					-- name of new instrument
	@iClass varchar(32),				-- class of instrument
	@iMethod varchar(10),				-- capture method of instrument
	@iRoomNum varchar(50),				-- where new instrument is located
	@iDescription varchar(50),			-- description of instrument

	@sourceMachineName varchar(128),	-- Source Machine to capture data from
	@sourcePath varchar(255),			-- transfer directory on source machine
	
	@spPath varchar(255),				-- storage path on Storage Server
	@spVolClient  varchar(128),			-- Storage server name (UNC)
	@spVolServer  varchar(128),			-- Drive letter on storage server (local to server itself)
	
	@archivePath varchar(128),			-- storage path on EMSL archive
	@archiveServer varchar(64),			-- archive server name
	@archiveNote varchar(128),			-- note describing archive path 
	@Usage varchar(50),					-- optional description of instrument usage
	@OperationsRole varchar(50),		-- Production, QC, Research, or Unused
	@InstrumentGroup varchar(64),		-- Item in T_Instrument_Group
	@PercentEMSLOwned varchar(24),		-- % of instrument owned by EMSL; number between 0 and 100
	
	@AutoDefineStoragePath varchar(32) = 'No',	-- Set to Yes to enable auto-defining the storage path based on the @spPath and @archivePath related parameters
	@message varchar(512) output
)
As
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	declare @result int

	declare @spSourcePathID int
	declare @spStoragePathID int
	set @spSourcePathID = 2 -- valid reference to 'na' storage path for initial entry
	set @spStoragePathID = 2 -- valid reference to 'na' storage path for initial entry

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	Set @AutoDefineStoragePath = IsNull(@AutoDefineStoragePath, 'No')

	if IsNumeric(@PercentEMSLOwned) = 0
		RAISERROR ('Percent EMSL Owned should be a number between 0 and 100', 11, 4)

	Declare @PercentEMSLOwnedVal int
	set @PercentEMSLOwnedVal = Convert(int, @PercentEMSLOwned)
	
	if @PercentEMSLOwnedVal < 0 Or @PercentEMSLOwnedVal > 100
		RAISERROR ('Percent EMSL Owned should be a number between 0 and 100', 11, 4)
		
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
	-- Derive shared path name
	---------------------------------------------------
	--
	declare @archiveNetworkSharePath varchar(128)
	set @archiveNetworkSharePath = '\' + REPLACE(REPLACE(@archivePath, 'archive', 'a2.emsl.pnl.gov'), '/', '\')

	---------------------------------------------------
	-- Resolve Yes/No parameters to 0 or 1
	---------------------------------------------------
	--
	Declare @valAutoDefineStoragePath tinyint = 0

	If @AutoDefineStoragePath = 'Yes' Or @AutoDefineStoragePath = 'Y' OR @AutoDefineStoragePath = '1'
		Set @valAutoDefineStoragePath = 1

	---------------------------------------------------
	-- Define the @AutoSP variables
	-- Auto-populate if @valAutoDefineStoragePath is non-zero
	---------------------------------------------------
	--	
	Declare @AutoSPVolNameClient varchar(128)
	Declare @AutoSPVolNameServer varchar(128)
	Declare @AutoSPPathRoot varchar(128)
	Declare @AutoSPArchiveServerName varchar(64)
	Declare @AutoSPArchivePathRoot varchar(128)
	Declare @AutoSPArchiveSharePathRoot varchar(128)
	
	If @valAutoDefineStoragePath <> 0
	Begin
		Set @AutoSPVolNameClient = @spVolClient
		Set @AutoSPVolNameServer = @spVolServer
		Set @AutoSPPathRoot = @spPath
		Set @AutoSPArchiveServerName = @archiveServer
		Set @AutoSPArchivePathRoot = @archivePath
		Set @AutoSPArchiveSharePathRoot = @archiveNetworkSharePath	

		If IsNull(@AutoSPVolNameClient, '') <> '' AND @AutoSPVolNameClient NOT LIKE '%\'
			-- Auto-add a slash
			Set @AutoSPVolNameClient = @AutoSPVolNameClient + '\'

		If IsNull(@AutoSPVolNameServer, '') <> '' AND @AutoSPVolNameServer NOT LIKE '%\'
			-- Auto-add a slash
			Set @AutoSPVolNameServer = @AutoSPVolNameServer + '\'
				
		---------------------------------------------------
		-- Validate the @AutoSP parameteres
		---------------------------------------------------

		exec @myError = ValidateAutoStoragePathParams  @valAutoDefineStoragePath, @AutoSPVolNameClient, @AutoSPVolNameServer,
													   @AutoSPPathRoot, @AutoSPArchiveServerName, 
													   @AutoSPArchivePathRoot, @AutoSPArchiveSharePathRoot

	End
	
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
		IN_Group,
		IN_source_path_ID, 
		IN_storage_path_ID, 
		IN_capture_method, 
		IN_Room_Number, 
		IN_Description,
		IN_usage, 
		IN_operations_role,	
		Percent_EMSL_Owned,	
		Auto_Define_Storage_Path,
        Auto_SP_Vol_Name_Client,
        Auto_SP_Vol_Name_Server,
        Auto_SP_Path_Root,        
        Auto_SP_Archive_Server_Name,
        Auto_SP_Archive_Path_Root,
        Auto_SP_Archive_Share_Path_Root
	) VALUES (
		@iName, 
		@iID, 
		@iClass, 
		@InstrumentGroup,
		@spSourcePathID, 
		@spStoragePathID, 
		@iMethod, 
		@iRoomNum, 
		@iDescription,
		IsNull(@Usage, ''),
		@OperationsRole,
		@PercentEMSLOwnedVal,
		@valAutoDefineStoragePath,
		@AutoSPVolNameClient,
		@AutoSPVolNameServer,
		@AutoSPPathRoot,		
		@AutoSPArchiveServerName,
		@AutoSPArchivePathRoot,
		@AutoSPArchiveSharePathRoot
	)
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	if @myError <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Insert into x table was unsuccessful for add instrument',
			10, 1)
		return 51131
	end

	If @valAutoDefineStoragePath <> 0
		Set @result = 0
	Else
	Begin
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
	End
	
	--
	if @result <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Creating storage path was unsuccessful for add instrument',
			10, 1)
		return 51132
	end

	---------------------------------------------------
	-- Make new source (inbox) directory in storage table
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

	If @valAutoDefineStoragePath = 0
	Begin -- <a>
		---------------------------------------------------
		-- add new archive storage path for new instrument
		---------------------------------------------------
		--
		-- get new archive ID
		--
		declare @aID int
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
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		If @myError = 0
		Begin
			set @aID = SCOPE_IDENTITY()
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
		End
		
		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR ('Insert into archive path table was unsuccessful for add instrument',
				10, 1)
			return 51134
		end
	End -- </a>

	---------------------------------------------------
	-- Finalize the transaction
	---------------------------------------------------
	--
	commit transaction @transName
	
	return 0

GO
GRANT EXECUTE ON [dbo].[AddNewInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewInstrument] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewInstrument] TO [PNL\D3M578] AS [dbo]
GO
