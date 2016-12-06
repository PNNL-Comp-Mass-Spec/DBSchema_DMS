/****** Object:  StoredProcedure [dbo].[AddUpdateInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateInstrument]
/****************************************************
**
**	Desc: Edits existing Instrument
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	06/07/2005 grk - Initial release
**			10/15/2008 grk - Allowed for null Usage
**			08/27/2010 mem - Added parameter @InstrumentGroup
**					       - try-catch for error handling
**			05/12/2011 mem - Added @AutoDefineStoragePath and related @AutoSP parameters
**			05/13/2011 mem - Now calling ValidateAutoStoragePathParams
**			11/30/2011 mem - Added parameter @PercentEMSLOwned
**			04/01/2013 mem - Expanded @Description to varchar(255)
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**			12/05/2016 mem - Exclude logging some try/catch errors
**    
*****************************************************/
(
	@InstrumentID int Output,
	@InstrumentName varchar(24),
	@InstrumentClass varchar(32),
	@InstrumentGroup varchar(64),
	@CaptureMethod varchar(10),
	@Status varchar(8),
	@RoomNumber varchar(50),
	@Description varchar(255),
	@Usage varchar(50),
	@OperationsRole varchar(50),
	@PercentEMSLOwned varchar(24),				-- % of instrument owned by EMSL; number between 0 and 100

	@AutoDefineStoragePath varchar(32) = 'No',	-- Set to Yes to enable auto-defining the storage path based on the @spPath and @archivePath related parameters
	@AutoSPVolNameClient varchar(128),
	@AutoSPVolNameServer varchar(128),
	@AutoSPPathRoot varchar(128),
	@AutoSPArchiveServerName varchar(64),
	@AutoSPArchivePathRoot varchar(128),
	@AutoSPArchiveSharePathRoot varchar(128),
	
	@mode varchar(12) = 'update',			-- Note that 'add' is not allowed in this procedure; instead use http://dms2.pnl.gov/new_instrument/create (which in turn calls AddNewInstrument)
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	BEGIN TRY
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	
	if @Usage is null
		set @Usage = ''

	Declare @PercentEMSLOwnedVal int = Try_Convert(Int, @PercentEMSLOwned)
	if @PercentEMSLOwnedVal Is Null Or @PercentEMSLOwnedVal < 0 Or @PercentEMSLOwnedVal > 100
		RAISERROR ('Percent EMSL Owned should be a number between 0 and 100', 11, 4)
		
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = Instrument_ID
		FROM  T_Instrument_Name
		WHERE (IN_name = @InstrumentName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 4)
	
	end

	---------------------------------------------------
	-- Resolve Yes/No parameters to 0 or 1
	---------------------------------------------------
	--
	Declare @valAutoDefineStoragePath tinyint = 0

	If @AutoDefineStoragePath = 'Yes' Or @AutoDefineStoragePath = 'Y' OR @AutoDefineStoragePath = '1'
		Set @valAutoDefineStoragePath = 1
	
	---------------------------------------------------
	-- Validate the @AutoSP parameteres
	---------------------------------------------------

	exec @myError = ValidateAutoStoragePathParams  @valAutoDefineStoragePath, @AutoSPVolNameClient, @AutoSPVolNameServer,
                                                   @AutoSPPathRoot, @AutoSPArchiveServerName, 
                                                   @AutoSPArchivePathRoot, @AutoSPArchiveSharePathRoot

	if @myError <> 0
		return @myError
	
	---------------------------------------------------
	-- Note: the add mode is not enabled in this stored procedure
	---------------------------------------------------
	if @Mode = 'add'
	begin
		RAISERROR ('The "add" instrument mode is disabled for this page; instead, use http://dms2.pnl.gov/new_instrument/create', 11, 5)	 
	end 

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
			
		UPDATE T_Instrument_Name
		SET IN_name = @InstrumentName,
		    IN_class = @InstrumentClass,
		    IN_Group = @InstrumentGroup,
		    IN_capture_method = @CaptureMethod,
		    IN_status = @Status,
		    IN_Room_Number = @RoomNumber,
		    IN_Description = @Description,
		    IN_usage = @Usage,
		    IN_operations_role = @OperationsRole,
		    Percent_EMSL_Owned = @PercentEMSLOwnedVal,
		    Auto_Define_Storage_Path = @valAutoDefineStoragePath,
		    Auto_SP_Vol_Name_Client = @AutoSPVolNameClient,
		    Auto_SP_Vol_Name_Server = @AutoSPVolNameServer,
		    Auto_SP_Path_Root = @AutoSPPathRoot,
		    Auto_SP_Archive_Server_Name = @AutoSPArchiveServerName,
		    Auto_SP_Archive_Path_Root = @AutoSPArchivePathRoot,
		    Auto_SP_Archive_Share_Path_Root = @AutoSPArchiveSharePathRoot
		WHERE (Instrument_ID = @InstrumentID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed', 11, 7)
		
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If Not @message Like '%should be a number%' And 
		   Not @message Like '%disabled for this page%' And 
		   Not @message Like '%No entry could be found%'
		Begin
			Declare @logMessage varchar(1024) = @message + '; Instrument ' + @InstrumentName		
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateInstrument'
		End

	END CATCH
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS_Instrument_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [Limited_Table_Write] AS [dbo]
GO
