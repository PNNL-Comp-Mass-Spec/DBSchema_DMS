/****** Object:  StoredProcedure [dbo].[AddUpdateOSMPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateOSMPackage 
/****************************************************
**
**  Desc: 
**    Adds new or edits existing item in 
**    T_OSM_Package 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date:
**          10/26/2012 grk - now setting "last affected" date
**          11/02/2012 grk - removed @Requester
**          05/20/2013 grk - added @NoteFilesLink
**          07/06/2013 grk - added @samplePrepRequestList
**          08/20/2013 grk - added handling for onenote file path
**          08/21/2013 grk - removed @NoteFilesLink
**          08/21/2013 grk - added call to create onenote folder
**          11/04/2013 grk - added @UserFolderPath
**			02/23/2016 mem - Add set XACT_ABORT on
**			05/18/2016 mem - Log errors to T_Log_Entries
**    
*****************************************************/
(
	@ID INT OUTPUT,
	@Name varchar(128),
	@PackageType varchar(128),
	@Description varchar(2048),
	@Keywords varchar(2048),
	@Comment varchar(1024),
	@Owner varchar(128),
	@State varchar(32),
	@SamplePrepRequestList VARCHAR(4096),
	@UserFolderPath VARCHAR(512),
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
	-- Get active path
	---------------------------------------------------
	--
	declare @rootPath int
	--
	SELECT @rootPath = ID
	FROM T_OSM_Package_Storage
	WHERE State = 'Active'
	
	---------------------------------------------------
	-- validate sample prep request list
	---------------------------------------------------
	
	-- Table variable to hold items from sample prep request list
	DECLARE @ITM TABLE (
		Item INT,
		Valid CHAR(1) null
	)
	-- populate table from sample prep request list 
	INSERT INTO @ITM ( Item, Valid)
	SELECT Item, 'N' FROM dbo.MakeTableFromList(@SamplePrepRequestList)
	
	-- mark sample prep requests that exist in the database
	UPDATE TX
	SET Valid = 'Y'
	FROM @ITM TX INNER JOIN dbo.S_Sample_Prep_Request_List SPL ON TX.Item = SPL.ID
	
	-- get list of any list items that weren't in the database
	DECLARE @badIDs VARCHAR(1024) = ''
	SELECT @badIDs = @badIDs + CASE WHEN @badIDs <> '' THEN ', ' + CONVERT(VARCHAR(12), Item) ELSE CONVERT(VARCHAR(12), Item) END
	FROM @ITM 
	WHERE Valid = 'N'
	
	IF @badIDs <> ''
	Begin
		set @message = 'Sample prep request IDs "' + @badIDs + '" do not exist'
		RAISERROR (@message, 11, 31)
	End

	DECLARE @goodIDs VARCHAR(1024) = ''
	SELECT @goodIDs = @goodIDs + CASE WHEN @goodIDs <> '' THEN ', ' + CONVERT(VARCHAR(12), Item) ELSE CONVERT(VARCHAR(12), Item) END
	FROM @ITM
	ORDER BY Item


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
		FROM  T_OSM_Package		WHERE (ID = @ID)
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

	-- Make sure the data package name doesn't already exist
	If Exists (SELECT * FROM T_OSM_Package WHERE Name = @Name)
	Begin
		set @message = 'OSM package name "' + @Name + '" already exists; cannot create an identically named package'
		RAISERROR (@message, 11, 1)
	End

	-- create wiki page link
	DECLARE @wikiLink VARCHAR(1024) = ''
	if NOT @Name IS NULL
	BEGIN
		SET @wikiLink = 'http://prismwiki.pnl.gov/wiki/OSMPackages:' + REPLACE(@Name, ' ', '_')
	END 

	INSERT INTO T_OSM_Package (
		Name,
		Package_Type,
		Description,
		Keywords,
		Comment,
		Owner,
		State,
		Wiki_Page_Link,
		Path_Root,
		Sample_Prep_Requests,
		User_Folder_Path
	) VALUES (
		@Name,
		@PackageType,
		@Description,
		@Keywords,
		@Comment,
		@Owner,
		@State,
		@wikiLink,
		@rootPath,
		@goodIDs,
		@UserFolderPath
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Insert operation failed', 11, 7)

	-- return ID of newly created entry
	--
	set @ID = IDENT_CURRENT('T_OSM_Package')

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_OSM_Package 
		SET 
			Name = @Name,
			Package_Type = @PackageType,
			Description = @Description,
			Keywords = @Keywords,
			Comment = @Comment,
			Owner = @Owner,
			State = @State,
			Last_Modified = GETDATE(),
			Sample_Prep_Requests = @goodIDs,
			User_Folder_Path = @UserFolderPath
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

	end -- update mode

	---------------------------------------------------
	-- Create the OSM package folder when adding a new OSM package
	---------------------------------------------------
	if @mode = 'add'
		exec @myError = MakeOSMPackageStorageFolder @ID, @mode, @message=@message output, @callingUser=@callingUser

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'AddUpdateOSMPackage'
				
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateOSMPackage] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOSMPackage] TO [DMS_SP_User] AS [dbo]
GO
