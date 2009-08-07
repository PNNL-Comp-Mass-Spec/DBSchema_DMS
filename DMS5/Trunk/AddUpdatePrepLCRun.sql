/****** Object:  StoredProcedure [dbo].[AddUpdatePrepLCRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdatePrepLCRun
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Prep_LC_Run
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 08/04/2009
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ID int output,
	@Tab varchar(128),
	@Instrument varchar(128),
	@Type varchar(64),
	@LCColumn varchar(128),
	@Comment varchar(1024),
	@GuardColumn varchar(12),
	@OperatorPRN varchar(50),
	@DigestionMethod varchar(128),
	@SampleType varchar(64),
	@Project varchar(64),
	@NumberOfRuns varchar(12),
	@InstrumentPressure varchar(32),
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

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_Prep_LC_Run
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

	INSERT INTO T_Prep_LC_Run (
		Tab,
		Instrument,
		Type,
		LC_Column,
		Comment,
		Guard_Column,
		OperatorPRN,
		Digestion_Method,
		Sample_Type,
		Project,
		Number_Of_Runs,
		Instrument_Pressure
	) VALUES (
		@Tab,
		@Instrument,
		@Type,
		@LCColumn,
		@Comment,
		@GuardColumn,
		@OperatorPRN,
		@DigestionMethod,
		@SampleType,
		@Project,
		@NumberOfRuns,
		@InstrumentPressure
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Insert operation failed'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_Prep_LC_Run')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Prep_LC_Run 
		SET
		Tab = @Tab,
		Instrument = @Instrument,
		Type = @Type,
		LC_Column = @LCColumn,
		Comment = @Comment,
		Guard_Column = @GuardColumn,
		OperatorPRN = @OperatorPRN,
		Digestion_Method = @DigestionMethod,
		Sample_Type = @SampleType,
		Project = @Project,
		Number_Of_Runs = @NumberOfRuns,
		Instrument_Pressure = @InstrumentPressure
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end -- update mode

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCRun] TO [DMS_SP_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCRun] TO [DMS2_SP_User]
GO
