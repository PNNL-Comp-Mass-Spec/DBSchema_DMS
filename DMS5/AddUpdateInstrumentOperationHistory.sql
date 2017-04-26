/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentOperationHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateInstrumentOperationHistory
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Instrument_Operation_History
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 05/20/2010
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			04/25/2017 mem - Require that @Instrument and @Note be defined
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/

	@ID int,
	@Instrument varchar(24),
	@postedBy VARCHAR(64),
	@Note text,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	Declare @logErrors tinyint = 0
	
	
	BEGIN TRY
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	If IsNull(@Instrument, '') = ''
	Begin
		RAISERROR ('Instrument name not defined', 11, 16)
	End 

	If @Note Is Null
	Begin
		RAISERROR ('Note cannot be blank', 11, 16)
	End 

	If @mode = 'update' and @ID is null
	Begin
		RAISERROR ('ID cannot be null when updating a note', 11, 16)
	End 

	---------------------------------------------------
	-- Resolve poster PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @postedBy
	if @userID = 0
	begin
		-- Could not find entry in database for PRN @postedBy
		-- Try to auto-resolve the name

		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @postedBy, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @postedBy
			Set @postedBy = @NewPRN
		End
	end

	Set @logErrors = 1

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
		SELECT @tmp = ID
		FROM  T_Instrument_Operation_History
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

	INSERT INTO T_Instrument_Operation_History (
		Instrument,
		EnteredBy,
		Note
	) VALUES (
		@Instrument,
		@postedBy,
		@Note
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_Instrument_Operation_History')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Instrument_Operation_History 
		SET 
		Instrument = @Instrument,
		Note = @Note
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Instrument ' + @Instrument
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateInstrumentOperationHistory'
		End
			
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentOperationHistory] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentOperationHistory] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentOperationHistory] TO [Limited_Table_Write] AS [dbo]
GO
