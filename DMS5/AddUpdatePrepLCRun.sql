/****** Object:  StoredProcedure [dbo].[AddUpdatePrepLCRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdatePrepLCRun]
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
**			04/24/2010 grk - replaced @project with @SamplePrepRequest
**			04/26/2010 grk - @SamplePrepRequest can be multiple
**			05/06/2010 grk - added storage path
**			08/25/2011 grk - added QC field
**			09/30/2011 grk - added datasets field
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ID int output,
	@Tab varchar(128),
	@Instrument varchar(128),
	@Type varchar(64),
	@LCColumn varchar(128),	
	@LCColumn2 varchar(128),
	@Comment varchar(1024),
	@GuardColumn varchar(12),
	@OperatorPRN varchar(50),
	@DigestionMethod varchar(128),
	@SampleType varchar(64),
	@SamplePrepRequest varchar(1024),
	@NumberOfRuns varchar(12),
	@InstrumentPressure varchar(32),
	@QualityControl varchar(2048),
	@Datasets varchar(MAX),	
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

	BEGIN TRY 

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
			RAISERROR ('No entry could be found in database for update', 11, 7)
	end

	---------------------------------------------------
	-- resolve dataset list
	---------------------------------------------------	CREATE TABLE #DSL (
	  Dataset VARCHAR(128) ,
	  Dataset_ID INT NULL
	)

	INSERT INTO #DSL
	( Dataset )
	SELECT Item AS Dataset
	FROM dbo.MakeTableFromList(@datasets)

	UPDATE #DSL
	SET Dataset_ID = dbo.T_Dataset.Dataset_ID
	FROM #DSL
	INNER JOIN dbo.T_Dataset ON #DSL.Dataset = dbo.T_Dataset.Dataset_Num

	---------------------------------------------------
	-- define transaction
	---------------------------------------------------	declare @transName varchar(32) = 'AddUpdatePrepLCRun'

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		---------------------------------------------------
		begin transaction @transName

		---------------------------------------------------
		--
		INSERT INTO T_Prep_LC_Run (
			Tab,
			Instrument,
			Type,
			LC_Column,
			LC_Column_2,
			Comment,
			Guard_Column,
			OperatorPRN,
			Digestion_Method,
			Sample_Type,
			SamplePrepRequest,
			Number_Of_Runs,
			Instrument_Pressure,
			Quality_Control	
		) VALUES (
			@Tab,
			@Instrument,
			@Type,
			@LCColumn,
			@LCColumn2,
			@Comment,
			@GuardColumn,
			@OperatorPRN,
			@DigestionMethod,
			@SampleType,
			@SamplePrepRequest,
			@NumberOfRuns,
			@InstrumentPressure,
			@QualityControl 
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed', 11, 8)

		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Prep_LC_Run')

		INSERT INTO dbo.T_Prep_LC_Run_Dataset
		        ( Prep_LC_Run_ID, Dataset_ID )
		SELECT @ID AS Prep_LC_Run_ID, Dataset_ID 
		FROM #DSL				
		
		commit transaction @transName
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		---------------------------------------------------
		begin transaction @transName
		
		set @myError = 0
		--
		UPDATE T_Prep_LC_Run 
		SET
		Tab = @Tab,
		Instrument = @Instrument,
		Type = @Type,
		LC_Column = @LCColumn,    
		LC_Column_2 = @LCColumn2,	
		Comment = @Comment,
		Guard_Column = @GuardColumn,
		OperatorPRN = @OperatorPRN,
		Digestion_Method = @DigestionMethod,
		Sample_Type = @SampleType,
		SamplePrepRequest = @SamplePrepRequest,
		Number_Of_Runs = @NumberOfRuns,
		Instrument_Pressure = @InstrumentPressure,
		Quality_Control = @QualityControl 
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

		-- add new datasets
		INSERT INTO dbo.T_Prep_LC_Run_Dataset
		        ( Prep_LC_Run_ID, Dataset_ID )
		SELECT @ID AS Prep_LC_Run_ID, Dataset_ID 
		FROM #DSL
		WHERE NOT #DSL.Dataset_ID IN (SELECT Dataset_ID FROM T_Prep_LC_Run_Dataset WHERE Prep_LC_Run_ID = @ID)
		
		-- delete removed datasets
		DELETE FROM T_Prep_LC_Run_Dataset
		WHERE Prep_LC_Run_ID = @ID 
		AND NOT T_Prep_LC_Run_Dataset.Dataset_ID IN (SELECT Dataset_ID FROM #DSL)

		commit transaction @transName
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
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCRun] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePrepLCRun] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePrepLCRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePrepLCRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePrepLCRun] TO [PNL\D3M580] AS [dbo]
GO
