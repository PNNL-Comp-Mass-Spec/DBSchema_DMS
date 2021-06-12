/****** Object:  StoredProcedure [dbo].[AddUpdateFileAttachment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateFileAttachment]
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
**          06/11/2021 mem - Store integers in Entity_ID_Value
**    
*****************************************************/
(
	@id int,
	@fileName varchar(256),
	@description varchar(1024),
	@entityType varchar(64),			-- campaign, experiment, sample_prep_request, lc_cart_configuration, etc.
	@entityID varchar(256),				-- Must be data type varchar since Experiment, Campaign, Cell Culture, and Material Container file attachments are tracked via Experiment Name, Campaign Name, etc.
	@fileSizeBytes varchar(12),			-- This file size is actually in KB
	@archiveFolderPath varchar(256),	-- This path is constructed when File_attachment.php or Experiment_File_attachment.php calls function GetFileAttachmentPath in this database
	@fileMimeType varchar(256),
	@mode varchar(12) = 'add',          -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateFileAttachment', @raiseError = 1
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	BEGIN TRY 

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------
	Declare @tmp int

	if @mode = 'update'
	begin
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM  T_File_Attachment		
		WHERE (ID = @id)
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
			Entity_Type = @entityType 
			AND Entity_ID = @entityID 
			AND [File_Name] = @fileName 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @tmp > 0
		BEGIN
			SET @mode = 'update'
			SET @id = @tmp
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
        Entity_ID_Value,
		Owner_PRN,
		File_Size_Bytes,
		Archive_Folder_Path,
		File_Mime_Type
	 ) VALUES (
		@fileName, 
		IsNull(@description, ''), 
		@entityType, 
		@entityID, 
        Case When @entityType In ('campaign', 'cell_culture', 'experiment', 'material_container') 
             Then Null 
             Else Try_Cast(@entityID As Int) 
        End,
		@callingUser, 
		@fileSizeBytes,
		@archiveFolderPath, 
		@fileMimeType
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- Return ID of newly created entry
	--
	set @id = SCOPE_IDENTITY()

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
		SET Description = IsNull(@description, ''),
		    Entity_Type = @entityType,
		    Entity_ID = @entityID,
            Entity_ID_Value = 
                Case When @entityType In ('campaign', 'cell_culture', 'experiment', 'material_container') 
                     Then Null 
                     Else Try_Cast(@entityID As Int) 
                End,
		    File_Size_Bytes = @fileSizeBytes,
		    Last_Affected = GETDATE(),
		    Archive_Folder_Path = @archiveFolderPath,
		    File_Mime_Type = @fileMimeType
		WHERE (ID = @id)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @id)

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
