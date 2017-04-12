/****** Object:  StoredProcedure [dbo].[AddUpdatePipelineMacJobRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdatePipelineMacJobRequest
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_MAC_Job_Request 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/19/2012 
**          03/26/2012 grk - added @ScheduledJob and @SchedulingNotes
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@ID INT output,
	@Description varchar(128),
	@RequestType varchar(128),
	@Requestor varchar(128),
	@DataPackageID int,
	@MTDatabase varchar(128),
	@Options varchar(2048),
	@Comment varchar(4096),
	@ScheduledJob int,
	@SchedulingNotes varchar(4096),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
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
		FROM  T_MAC_Job_Request		WHERE (ID = @ID)
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

	INSERT INTO T_MAC_Job_Request (
		Description,
		Request_Type,
		Requestor,
		Data_Package_ID,
		MT_Database,
		Options,
		Comment,
		Scheduled_Job,
		Scheduling_Notes
	) VALUES (
		@Description,
		@RequestType,
		@Requestor,
		@DataPackageID,
		@MTDatabase,
		@Options,
		@Comment,
		@ScheduledJob,
		@SchedulingNotes
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_MAC_Job_Request')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_MAC_Job_Request 
		SET 
			Description = @Description,
			Request_Type = @RequestType,
			Requestor = @Requestor,
			Data_Package_ID = @DataPackageID,
			MT_Database = @MTDatabase,
			Options = @Options,
			Comment = @Comment,
			Scheduled_Job = @ScheduledJob,
			Scheduling_Notes = @SchedulingNotes 			
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
			
		Exec PostLogEntry 'Error', @message, 'AddUpdatePipelineMacJobRequest'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePipelineMacJobRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePipelineMacJobRequest] TO [DMS_SP_User] AS [dbo]
GO
