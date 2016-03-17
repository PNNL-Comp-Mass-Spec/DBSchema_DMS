/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateInstrumentUsageReport 
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_EMSL_Instrument_Usage_Report 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/27/2012 
**          09/11/2012 grk - changed type of @Start
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@Seq int,
	@EMSLInstID int,
	@Instrument varchar(64),
	@Type varchar(128),
	@Start VARCHAR(32),
	@Minutes int,
	@Year int,
	@Month int,
	@ID int,
	@Proposal varchar(32),
	@Usage varchar(32),
	@Users varchar(1024),
	@Operator varchar(64),
	@Comment varchar(4096),
	@mode varchar(12) = 'update', 
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	Set XACT_ABORT, nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	---------------------------------------------------
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
		FROM  T_EMSL_Instrument_Usage_Report		WHERE (Seq = @Seq)
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
		RAISERROR ('"Add" mode not supported', 11, 7)
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_EMSL_Instrument_Usage_Report 
		SET 		
			Proposal = @Proposal,
			Usage = @Usage,
			Users = @Users,
			Operator = @Operator,
			Comment = @Comment
		WHERE (Seq = @Seq)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @Seq)

	end -- update mode

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentUsageReport] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentUsageReport] TO [PNL\D3M580] AS [dbo]
GO
