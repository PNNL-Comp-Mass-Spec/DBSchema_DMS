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
**	Auth:	grk
**	Date:	03/19/2012 
**			03/26/2012 grk - added @ScheduledJob and @SchedulingNotes
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Add Goto Done after RAISERROR
**
*****************************************************/
(
	@ID int output,
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

	declare @myError int = 0
	declare @myRowCount int = 0

	set @message = ''

	BEGIN TRY 
	
	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdatePipelineMacJobRequest', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
		Goto Done
	End

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
		Begin
			RAISERROR ('No entry could be found in database for update', 11, 16)
			Goto Done
		End
	end

	---------------------------------------------------
	-- Action for add mode
	---------------------------------------------------
	--
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
	Begin
		RAISERROR ('Insert operation failed', 11, 7)
		Goto Done
	End
	
	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_MAC_Job_Request')

	end -- add mode

	---------------------------------------------------
	-- Action for update mode
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
		Begin
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)
			Goto Done
		End		
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

Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdatePipelineMacJobRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdatePipelineMacJobRequest] TO [DMS_SP_User] AS [dbo]
GO
