/****** Object:  StoredProcedure [dbo].[AddUpdateLCColumn] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateLCColumn
/****************************************************
**
**	Desc: Adds a new entry to LC Column table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	12/09/2003
**			08/19/2010 grk - try-catch for error handling
**			02/23/2016 mem - Add set XACT_ABORT on
**          07/20/2016 mem - Fix error message entity name
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			05/19/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
*****************************************************/
(
	@columnNumber varchar (128),		-- Aka column name
	@packingMfg varchar (64),
	@packingType varchar (64),
	@particleSize varchar (64),
	@particleType varchar (64),
	@columnInnerDia varchar (64),
	@columnOuterDia varchar (64),
	@length varchar (64),
	@state  varchar (32),
	@operator_prn varchar (50),
	@comment varchar (244),
	--
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''
	
	Declare @msg varchar(256)
	Declare @logErrors tinyint = 1

	BEGIN TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateLCColumn', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@columnNumber) < 1
	begin
		set @myError = 51110
		RAISERROR ('Column name was blank', 11, 1)
	end
	
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @columnID int = -1
	--
	SELECT @columnID = ID
	FROM T_LC_Column
	WHERE (SC_Column_Number = @columnNumber)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error while trying to find existing entry in database'
		RAISERROR (@msg, 11, 2)
	end

	-- cannot create an entry that already exists
	--
	if @columnID <> -1 and @mode = 'add'
	begin
		Set @logErrors = 0
		set @msg = 'Cannot add: Specified LC column already in database'
		RAISERROR (@msg, 11, 3)
	end

	-- cannot update a non-existent entry
	--
	if @columnID = -1 and @mode = 'update'
	begin
		Set @logErrors = 0
		set @msg = 'Cannot update: Specified LC column is not in database'
		RAISERROR (@msg, 11, 5)
	end

	---------------------------------------------------
	-- Resolve ID for state
	---------------------------------------------------

	Declare @stateID int = -1
	--
	SELECT @stateID = LCS_ID
	FROM T_LC_Column_State_Name
	WHERE LCS_Name = @state	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up state ID'
		RAISERROR (@msg, 11, 6)
	end
	if @stateID = -1
	begin
		Set @logErrors = 0
		set @msg = 'Invalid column state: ' + @state
		RAISERROR (@msg, 11, 7)
	end


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		INSERT INTO T_LC_Column
		(
			SC_Column_Number,
			SC_Packing_Mfg,
			SC_Packing_Type,
			SC_Particle_size,
			SC_Particle_type,
			SC_Column_Inner_Dia,
			SC_Column_Outer_Dia,
			SC_Length,
			SC_State,
			SC_Operator_PRN,
			SC_Comment,
			SC_Created
		) VALUES (
			@columnNumber,
			@packingMfg,
			@packingType,
			@particleSize,
			@particleType,
			@columnInnerDia,
			@columnOuterDia,
			@length,
			@stateID,
			@operator_prn,
			@comment,
			GETDATE()
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed'
			RAISERROR (@msg, 11, 8)
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
		UPDATE T_LC_Column 
		SET 
			SC_Column_Number = @columnNumber,
			SC_Packing_Mfg = @packingMfg,
			SC_Packing_Type = @packingType,
			SC_Particle_size = @particleSize,
			SC_Particle_type = @particleType,
			SC_Column_Inner_Dia = @columnInnerDia,
			SC_Column_Outer_Dia = @columnOuterDia,
			SC_Length = @length,
			SC_State = @stateID,
			SC_Operator_PRN = @operator_prn,
			SC_Comment = @comment
		WHERE (ID = @columnID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed'
			RAISERROR (@msg, 11, 9)
		end
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		If @logErrors > 0
		Begin
			Exec PostLogEntry 'Error', @message, 'AddUpdateLCColumn'
		End
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCColumn] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCColumn] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCColumn] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCColumn] TO [Limited_Table_Write] AS [dbo]
GO
