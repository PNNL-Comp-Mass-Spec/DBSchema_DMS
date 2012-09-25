/****** Object:  StoredProcedure [dbo].[AddUpdateOperationsTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateOperationsTasks] 
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_Operations_Tasks 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 09/01/2012 
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	
	@ID int output,
	@Tab varchar(64),
	@Requestor varchar(64),
	@RequestedPersonal varchar(256),
	@AssignedPersonal varchar(256),
	@Description varchar(5132),
	@Comments varchar(MAX),
	@Status varchar(32),
	@Priority varchar(32),
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
		FROM  T_Operations_Tasks		WHERE (ID = @ID)
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

	INSERT INTO T_Operations_Tasks (
		Tab,
		Requestor,
		Requested_Personal,
		Assigned_Personal,
		Description,
		Comments,
		Status,
		Priority
	) VALUES (
		@Tab,
		@Requestor,
		@RequestedPersonal,
		@AssignedPersonal,
		@Description,
		@Comments,
		@Status,
		@Priority 
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_Operations_Tasks')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Operations_Tasks 
		SET 
		Tab = @Tab,
		Requestor = @Requestor,
		Requested_Personal = @RequestedPersonal,
		Assigned_Personal = @AssignedPersonal,
		Description = @Description,
		Comments = @Comments,
		Status = @Status,
		Priority = @Priority
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
