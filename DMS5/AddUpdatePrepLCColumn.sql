/****** Object:  StoredProcedure [dbo].[AddUpdatePrepLCColumn] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdatePrepLCColumn
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Prep_LC_Column
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 07/29/2009
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ColumnName varchar(128),
	@MfgName varchar(128),
	@MfgModel varchar(128),
	@MfgSerialNumber varchar(64),
	@PackingMfg varchar(64),
	@PackingType varchar(64),
	@Particlesize varchar(64),
	@Particletype varchar(64),
	@ColumnInnerDia varchar(64),
	@ColumnOuterDia varchar(64),
	@Length varchar(64),
	@State varchar(32),
	@OperatorPRN varchar(50),
	@Comment varchar(244),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	
	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM  T_Prep_LC_Column
	WHERE Column_Name = @ColumnName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for existing entry'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	if @mode = 'update' and @tmp = 0
	begin
		set @message = 'No entry could be found in database for update'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	if @mode = 'add' and @tmp <> 0
	begin
		set @message = 'Cannot add a duplicate entry'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

	INSERT INTO T_Prep_LC_Column (
		Column_Name,
		Mfg_Name,
		Mfg_Model,
		Mfg_Serial_Number,
		Packing_Mfg,
		Packing_Type,
		Particle_size,
		Particle_type,
		Column_Inner_Dia,
		Column_Outer_Dia,
		Length,
		State,
		Operator_PRN,
		Comment
	) VALUES (
		@ColumnName,
		@MfgName,
		@MfgModel,
		@MfgSerialNumber,
		@PackingMfg,
		@PackingType,
		@Particlesize,
		@Particletype,
		@ColumnInnerDia,
		@ColumnOuterDia,
		@Length,
		@State,
		@OperatorPRN,
		@Comment
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Insert operation failed'
		RAISERROR (@message, 10, 1)
		return 51010
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
		UPDATE T_Prep_LC_Column 
		SET 
			Mfg_Name = @MfgName,
			Mfg_Model = @MfgModel,
			Mfg_Serial_Number = @MfgSerialNumber,
			Packing_Mfg = @PackingMfg,
			Packing_Type = @PackingType,
			Particle_size = @Particlesize,
			Particle_type = @Particletype,
			Column_Inner_Dia = @ColumnInnerDia,
			Column_Outer_Dia = @ColumnOuterDia,
			Length = @Length,
			State = @State,
			Operator_PRN = @OperatorPRN,
			Comment = @Comment
		WHERE 
			Column_Name = @ColumnName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ColumnName + '"'
			RAISERROR (@message, 10, 1)
			return 51011
		end
	end -- update mode

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePrepLCColumn] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCColumn] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCColumn] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePrepLCColumn] TO [Limited_Table_Write] AS [dbo]
GO
