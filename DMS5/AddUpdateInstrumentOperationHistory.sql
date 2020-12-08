/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentOperationHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateInstrumentOperationHistory]
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in
**    T_Instrument_Operation_History
**
**  Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	05/20/2010
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			04/25/2017 mem - Require that @Instrument and @Note be defined
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			08/02/2017 mem - Assure that the username is properly capitalized
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@Instrument varchar(24),
	@postedBy VARCHAR(64),
	@Note text,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Set @message = ''

	Declare @logErrors tinyint = 0

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------

	Declare @authorized tinyint = 0
	Exec @authorized = VerifySPAuthorized 'AddUpdateInstrumentOperationHistory', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

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

	Declare @userID int
	execute @userID = GetUserID @postedBy

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @postedBy contains simply the username
        --
        SELECT @postedBy = U_PRN
        FROM T_Users
	    WHERE ID = @userID
    End
    Else
    Begin
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
	End

	Set @logErrors = 1

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	If @mode = 'update'
	Begin
		-- cannot update a non-existent entry
		--
		Declare @tmp int = 0
		--
		SELECT @tmp = ID
		FROM  T_Instrument_Operation_History
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
	End

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	If @Mode = 'add'
	Begin

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
		If @myError <> 0
			RAISERROR ('Insert operation failed', 11, 7)

		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @Mode = 'update'
	Begin
		set @myError = 0
		--
		UPDATE T_Instrument_Operation_History
		SET Instrument = @Instrument,
		    Note = @Note
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	End -- update mode

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
