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
**  Auth:	grk
**  Date:	03/27/2012 
**          09/11/2012 grk - changed type of @Start
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/11/2017 mem - Replace column Usage with Usage_Type
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@Seq int,
	@EMSLInstID int,					-- @EMSLInstID
	@Instrument varchar(64),			-- Unused (not updatable)
	@Type varchar(128),					-- Unused (not updatable)
	@Start varchar(32),					-- Unused (not updatable)
	@Minutes int,						-- Unused (not updatable)
	@Year int,							-- Unused (not updatable)
	@Month int,							-- Unused (not updatable)
	@ID int,							-- Unused (not updatable)
	@Proposal varchar(32),				-- Proposal for update
	@Usage varchar(32),					-- Usage name for update
	@Users varchar(1024),				-- Users forupdate
	@Operator varchar(64),				-- Operator for update
	@Comment varchar(4096),				-- Comment for update
	@mode varchar(12) = 'update',		-- The only supported mode is update
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateInstrumentUsageReport', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @mode = IsNull(@mode, '')
	Set @Usage = IsNull(@Usage, '')
	
	Declare @usageTypeID tinyint = 0
	
	SELECT @usageTypeID = ID
	FROM T_EMSL_Instrument_Usage_Type
	WHERE ([Name] = @Usage)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0 Or IsNull(@usageTypeID, 0) = 0
	Begin
		Declare @msg varchar(128) = 'Invalid usage ' + @Usage
		RAISERROR (@msg, 11, 16)
	End
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int = 0
		--
		SELECT @tmp = ID
		FROM  T_EMSL_Instrument_Usage_Report
		WHERE (Seq = @Seq)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @mode = 'add'
	begin
		RAISERROR ('"Add" mode not supported', 11, 7)
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_EMSL_Instrument_Usage_Report 
		SET 		
			Proposal = @Proposal,
			Usage_Type = @usageTypeID,
			Users = @Users,
			Operator = @Operator,
			Comment = @Comment
		WHERE (Seq = @Seq)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%d"', 11, 4, @Seq)

	end -- update mode

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateInstrumentUsageReport'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
