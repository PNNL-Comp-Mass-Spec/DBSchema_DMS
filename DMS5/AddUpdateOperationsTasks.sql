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
**    11/19/2012 grk - added work package and closed date
**    11/04/2013 grk - added @HoursSpent
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
	@WorkPackage VARCHAR(32),
	@HoursSpent VARCHAR(12),
	@Status varchar(32),
	@Priority varchar(32),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	SET NOCOUNT ON

	DECLARE @myError INT
	set @myError = 0

	DECLARE @myRowCount INT
	SET @myRowCount = 0

	SET @message = ''
	
	DECLARE @closed DATETIME = null

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	IF @Status IN ('Completed', 'Not Implemented')
	BEGIN 
		SET @closed = GETDATE() 
	END 
	
	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	BEGIN
		-- cannot update a non-existent entry
		--
		DECLARE @tmp INT = 0
		DECLARE @curStatus VARCHAR(32) = ''
		DECLARE @curClosed DATETIME = null
		--
		SELECT 
			@tmp = ID,
			@curStatus = Status,
			@curClosed = Closed
		FROM  T_Operations_Tasks
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
			
		IF @curStatus IN ('Completed', 'Not Implemented')
		BEGIN 
			SET @closed = @curClosed
		END 
		
	END

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	BEGIN

	INSERT INTO T_Operations_Tasks (
		Tab,
		Requestor,
		Requested_Personal,
		Assigned_Personal,
		Description,
		Comments,
		Status,
		Priority,
		Work_Package,
		Closed,
		Hours_Spent
	) VALUES (
		@Tab,
		@Requestor,
		@RequestedPersonal,
		@AssignedPersonal,
		@Description,
		@Comments,
		@Status,
		@Priority,
		@WorkPackage,
		@closed,
		@HoursSpent
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	IF @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	SET @ID = IDENT_CURRENT('T_Operations_Tasks')

	END -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	IF @Mode = 'update' 
	BEGIN
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
			Priority = @Priority,
			Work_Package = @WorkPackage,
			Closed = @closed,
			Hours_Spent = @HoursSpent
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	END -- update mode

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
GRANT EXECUTE ON [dbo].[AddUpdateOperationsTasks] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOperationsTasks] TO [DMS2_SP_User] AS [dbo]
GO
