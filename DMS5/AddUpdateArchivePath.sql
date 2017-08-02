/****** Object:  StoredProcedure [dbo].[AddUpdateArchivePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateArchivePath
/****************************************************
**
**	Desc: Adds new or updates existing archive paths in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@ArchiveID  unique identifier for the new archive path
**	
**
**	Auth: jds
**	Date:	06/24/2004 jds - initial release
**			12/29/2008 grk - Added @NetworkSharePath (http://prismtrac.pnl.gov/trac/ticket/708)
**			05/11/2011 mem - Expanded @ArchivePath, @ArchiveServer, @NetworkSharePath, and @ArchiveNote to larger varchar() variables
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@ArchiveID varchar(32) output,			-- ID value (as a string)
	@ArchivePath varchar(128),
	@ArchiveServer varchar(64),
	@instrumentName varchar(24),
	@NetworkSharePath varchar(128),
	@ArchiveNote varchar(128),
	@ArchiveFunction varchar(32),
	@mode varchar(12) = 'add',				-- 'add' or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateArchivePath', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@instrumentName) < 1
	begin
		set @myError = 51000
		RAISERROR ('Instrument Name was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	set @myError = 0
	if LEN(@ArchivePath) < 1
	begin
		set @myError = 51000
		RAISERROR ('Archive Path was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	set @myError = 0
	if LEN(@ArchiveFunction) < 1
	begin
		set @myError = 51000
		RAISERROR ('Archive Status was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @ArchiveID1 int
	set @ArchiveID1 = 0
	--
	execute @ArchiveID1 = GetArchivePathID @ArchivePath

	-- cannot create an entry that already exists
	--
	if @ArchiveID1 <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Archive Path "' + @ArchivePath + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------

	declare @instrumentID int
	execute @instrumentID = GetinstrumentID @instrumentName
	if @instrumentID = 0
	begin
		set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 10, 1)
		return 51014
	end


	---------------------------------------------------
	-- Resolve Archive function
	---------------------------------------------------
	--
	-- Check to see if changing existing "Active" to non active
	-- leaving no active archive path for current instrument
	--
	declare @tempArchiveID int
	if @ArchiveFunction <> 'Active'
	begin
		SELECT @tempArchiveID = AP_Path_ID 
		FROM T_Archive_Path
		WHERE AP_Path_ID = @ArchiveID AND AP_Function = 'Active'
		if @tempArchiveID <> 0
		begin
			set @msg = 'You are prevented from setting non Active for instrument "' + @instrumentName + '"'
			RAISERROR (@msg, 10, 1)
			return 51014
		end
	end


	---------------------------------------------------
	-- action for active instrument
	---------------------------------------------------
	--
	-- check for active instrument to prevent multiple Active paths for an instrument
	--
	declare @instrumentIDTemp int
	execute @instrumentIDTemp = GetActiveInstrumentID @instrumentName
	if @instrumentIDTemp <> 0 and @ArchiveFunction = 'Active'
	begin
		UPDATE T_Archive_Path 
		SET AP_Function = 'Old'
		WHERE AP_Path_ID in (Select AP_Path_ID FROM T_Instrument_Name 
			INNER JOIN T_Archive_Path ON Instrument_ID = AP_Instrument_Name_ID 
			and IN_name = @instrumentName and AP_Function = 'Active')
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	--
	-- insert new archive path
	--
	if @Mode = 'add'
	begin

		INSERT INTO T_Archive_Path (
			AP_Archive_Path, 
			AP_Server_Name, 
			AP_Instrument_Name_ID,
			AP_network_share_path,
			Note, 
			AP_Function 
		) VALUES (
			@ArchivePath,
			@ArchiveServer,
			@instrumentID,
			@NetworkSharePath,
			@ArchiveNote,
			@ArchiveFunction
		)

		-- return Archive ID of newly created archive
		--
		set @ArchiveID = SCOPE_IDENTITY()

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @ArchivePath + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- add mode



	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin

		set @myError = 0
		--
		UPDATE T_Archive_Path 
		SET 
			AP_Archive_Path = @ArchivePath,
			AP_Server_Name = @ArchiveServer,
			AP_Instrument_Name_ID = @instrumentID,
			AP_network_share_path = @NetworkSharePath,
			Note = @ArchiveNote,
			AP_Function = @ArchiveFunction
		WHERE (AP_Path_ID = @ArchiveID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @ArchivePath + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateArchivePath] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateArchivePath] TO [DMS_Archive_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateArchivePath] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateArchivePath] TO [Limited_Table_Write] AS [dbo]
GO
