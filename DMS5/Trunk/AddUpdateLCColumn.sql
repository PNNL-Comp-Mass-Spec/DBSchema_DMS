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
**		Auth: grk
**		Date: 12/9/2003
**    
*****************************************************/
	@columnNumber varchar (128),
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
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@columnNumber) < 1
	begin
		set @myError = 51110
		RAISERROR ('Dataset number was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError
	
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @columnID int
	set @columnID = -1
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
		RAISERROR (@msg, 10, 1)
		return 51007
	end

	-- cannot create an entry that already exists
	--
	if @columnID <> -1 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Specified column number already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @columnID = -1 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Specified column number is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- Resolve ID for state
	---------------------------------------------------

	declare @stateID int
	set @stateID = -1
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
		RAISERROR (@msg, 10, 1)
		return 51095
	end
	if @stateID = -1
	begin
		set @msg = 'Could not resolve state to ID'
		RAISERROR (@msg, 10, 1)
		return 51096
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
		)
		VALUES
		(
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
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode

	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateLCColumn] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCColumn] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCColumn] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCColumn] TO [PNL\D3M580] AS [dbo]
GO
