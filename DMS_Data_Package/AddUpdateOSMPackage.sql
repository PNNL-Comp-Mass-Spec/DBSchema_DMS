/****** Object:  StoredProcedure [dbo].[AddUpdateOSMPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateOSMPackage] 
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
**          10/22/2012 grk - initial release
**          10/26/2012 grk - now setting "last affected" date
**          11/02/2012 grk - removed @Requester
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
	
	@ID INT OUTPUT,
	@Name varchar(128),
	@PackageType varchar(128),
	@Description varchar(2048),
	@Keywords varchar(2048),
	@Comment varchar(1024),
	@Owner varchar(128),
	@State varchar(32),
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
		RAISERROR (@message, 10, 1)
	End
	-- create wiki page link	DECLARE @wikiLink VARCHAR(1024) = ''
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
		Wiki_Page_Link
	) VALUES (
		@Name,
		@PackageType,
		@Description,
		@Keywords,
		@Comment,
		@Owner,
		@State,
		@wikiLink
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
			Last_Modified = GETDATE()
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
GRANT EXECUTE ON [dbo].[AddUpdateOSMPackage] TO [DMS_SP_User] AS [dbo]
GO
