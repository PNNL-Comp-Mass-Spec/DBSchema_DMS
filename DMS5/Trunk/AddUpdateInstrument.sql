/****** Object:  StoredProcedure [dbo].[AddUpdateInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateInstrument
/****************************************************
**
**	Desc: Edits existing Instrument
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth: grk
**		06/07/2005 grk - Initial release
**		10/15/2008 grk - Allowed for null Usage
**		08/27/2010 mem - Added parameter @InstrumentGroup
**					   - try-catch for error handling
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
	@Description varchar(50),
	@Usage varchar(50),
	@OperationsRole varchar(50),
	@mode varchar(12) = 'update', -- 'add' has been disabled since 2008; instead use http://dms2.pnl.gov/new_instrument/create
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
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		RAISERROR ('The "add" instrument mode is disabled for this page; instead, use http://dms2.pnl.gov/new_instrument/create', 11, 5)
	 
		INSERT INTO T_Instrument_Name (
			IN_name, 
			IN_class, 
			IN_group,
			IN_capture_method, 
			IN_status, 
			IN_Room_Number, 
			IN_Description, 
			IN_usage, 
			IN_operations_role
		) VALUES (
			@InstrumentName, 
			@InstrumentClass,
			@InstrumentGroup, 
			@CaptureMethod, 
			@Status, 
			@RoomNumber, 
			@Description, 
			@Usage, 
			@OperationsRole
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed', 11, 6)
		  
		-- return ID of newly created entry
		--
		set @InstrumentID = IDENT_CURRENT('T_Instrument_Name')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--

		UPDATE T_Instrument_Name 
		SET 
			IN_name = @InstrumentName, 
			IN_class = @InstrumentClass, 
			IN_Group = @InstrumentGroup,
			IN_capture_method = @CaptureMethod, 
			IN_status = @Status, 
			IN_Room_Number = @RoomNumber, 
			IN_Description = @Description, 
			IN_usage = @Usage, 
			IN_operations_role = @OperationsRole
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
	END CATCH
	
	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS_Instrument_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [PNL\D3M580] AS [dbo]
GO
