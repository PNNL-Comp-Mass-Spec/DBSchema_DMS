/****** Object:  StoredProcedure [dbo].[AddUpdateFileAttachment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateFileAttachment
/****************************************************
**
**  Desc: Adds new or edits existing item in T_File_Attachment 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	03/30/2011 
**			03/30/2011 grk - don't allow duplicate entries
**			12/16/2011 mem - Convert null descriptions to empty strings
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/13/2017 mem - Use SCOPE_IDENTITY
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@ID int,
	@FileName varchar(256),
	@Description varchar(1024),
	@EntityType varchar(64),			-- campaign, experiment, sample_prep_request, lc_cart_configuration, etc.
	@EntityID varchar(256),				-- Must be text because Experiment and Campaign file attachments are tracked via Experiment Name or Campaign Name
	@FileSizeBytes varchar(12),			-- This file size is actually in KB
	@ArchiveFolderPath varchar(256),	-- This path is constructed when File_attachment.php or Experiment_File_attachment.php calls function GetFileAttachmentPath in this database
	@FileMimeType varchar(256),
	@mode varchar(12) = 'add', -- or 'update'
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
	Exec @authorized = VerifySPAuthorized 'AddUpdateFileAttachment', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY 

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	declare @tmp int

	if @mode = 'update'
	begin
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_File_Attachment		
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		-- cannot update a non-existent entry
		if @myError <> 0 OR @tmp = 0
			RAISERROR ('No entry could be found in database for update', 11, 16)
	end
	
	IF @mode = 'add'
	BEGIN
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM   T_File_Attachment
		WHERE  
			Entity_Type = @EntityType 
			AND Entity_ID = @EntityID 
			AND [File_Name] = @FileName 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @tmp > 0
		BEGIN
			SET @mode = 'update'
			SET @ID = @tmp
		END
	END 

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

	INSERT INTO T_File_Attachment (
		[File_Name],
		Description,
		Entity_Type,
		Entity_ID,
		Owner_PRN,
		File_Size_Bytes,
		Archive_Folder_Path,
		File_Mime_Type
	 ) VALUES (
		@FileName, 
		IsNull(@Description, ''), 
		@EntityType, 
		@EntityID, 
		@callingUser, 
		@FileSizeBytes,
		@ArchiveFolderPath, 
		@FileMimeType
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- Return ID of newly created entry
	--
	set @ID = SCOPE_IDENTITY()

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_File_Attachment
		SET Description = IsNull(@Description, ''),
		    Entity_Type = @EntityType,
		    Entity_ID = @EntityID,
		    File_Size_Bytes = @FileSizeBytes,
		    Last_Affected = GETDATE(),
		    Archive_Folder_Path = @ArchiveFolderPath,
		    File_Mime_Type = @FileMimeType
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
			
		Exec PostLogEntry 'Error', @message, 'AddUpdateFileAttachment'
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateFileAttachment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateFileAttachment] TO [DMS2_SP_User] AS [dbo]
GO
