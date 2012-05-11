/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartConfigHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLCCartConfigHistory 
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_LC_Cart_Config_History 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/09/2011 
**          03/26/2012 grk - added "PostedBy"
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	@ID int,
	@Cart varchar(128),
	@DateOfChange VARCHAR(32),
	@PostedBy VARCHAR(64),
	@Description varchar(128),
	@Note text,
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
	---------------------------------------------------
	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	IF @PostedBy IS NULL OR @PostedBy = ''
	BEGIN 
		SET @PostedBy = @callingUser
	END 

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
		FROM  T_LC_Cart_Config_History		
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

	INSERT INTO T_LC_Cart_Config_History (
		Cart,
		Date_Of_Change,
		Description,
		Note,
		EnteredBy
		) VALUES (
		@Cart,
		CASE WHEN @DateOfChange = '' THEN GETDATE() ELSE @DateOfChange END,
		@Description,
		@Note,
		@PostedBy
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_LC_Cart_Config_History')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_LC_Cart_Config_History 
		SET 
		Cart = @Cart,
		Date_Of_Change = @DateOfChange,
		Description = @Description,
		Note = @Note,
		EnteredBy = @PostedBy
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

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
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfigHistory] TO [DMS2_SP_User] AS [dbo]
GO
