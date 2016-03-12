/****** Object:  StoredProcedure [dbo].[AddUpdateDataPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateDataPackage
/****************************************************
**
**  Desc: Adds new or edits existing T_Data_Package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	05/21/2009 grk
**			05/29/2009 mem - Updated to support Package_File_Folder not allowing null values
**			06/04/2009 grk - Added parameter @creationParams
**						   - Updated to call MakeDataPackageStorageFolder
**			06/05/2009 grk - Added parameter @PRISMWikiLink, which is used to populate the Wiki_Page_Link field
**			06/08/2009 mem - Now validating @Team and @PackageType
**			06/09/2009 mem - Now warning user if the team name is changed
**			06/11/2009 mem - Now warning user if the data package name already exists
**			06/11/2009 grk - Added Requester field
**			07/01/2009 mem - Expanced @MassTagDatabase to varchar(1024)
**			10/23/2009 mem - Expanded @PRISMWikiLink to varchar(1024)
**			03/17/2011 mem - Removed extra, unused parameter from MakeDataPackageStorageFolder
**						   - Now only calling MakeDataPackageStorageFolder when @mode = 'add'
**			08/31/2015 mem - Now replacing the symbol & with 'and' in the name when @mode = 'add'
**			02/19/2016 mem - Now replacing a semicolon with a comma when @mode = 'add'
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int output,
	@Name varchar(128),
	@PackageType varchar(128),
	@Description varchar(2048),
	@Comment varchar(1024),
	@Owner varchar(128),
	@Requester varchar(128),
	@State varchar(32),
	@Team varchar(64),
	@MassTagDatabase varchar(1024),
	@PRISMWikiLink varchar(1024) output,
	@creationParams varchar(4096) output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @CurrentID int
	declare @TeamCurrent varchar(64)
	declare @TeamChangeWarning varchar(256)
	declare @PkgFileFolder varchar(256)

	set @TeamChangeWarning = ''
	set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @Team = IsNull(@Team, '')
	Set @PackageType = IsNull(@PackageType, '')
	Set @Description = IsNull(@Description, '')
	Set @Comment = IsNull(@Comment, '')
	

	If @Team = ''
	Begin
		set @message = 'Data package team cannot be blank'
		RAISERROR (@message, 10, 1)
		return 51005
	End
	
	If @PackageType = ''
	Begin
		set @message = 'Data package type cannot be blank'
		RAISERROR (@message, 10, 1)
		return 51006
	End
	
	-- Make sure the team name is valid
	If Not Exists (SELECT * FROM T_Data_Package_Teams WHERE Team_Name = @Team)
	Begin
		set @message = 'Teams "' + @Team + '" is not a valid data package team'
		RAISERROR (@message, 10, 1)
		return 51007
	End
	
	-- Make sure the data package type is valid
	If Not Exists (SELECT * FROM T_Data_Package_Type WHERE Name = @PackageType)
	Begin
		set @message = 'Type "' + @PackageType + '" is not a valid data package type'
		RAISERROR (@message, 10, 1)
		return 51008
	End

	---------------------------------------------------
	-- Get active path
	---------------------------------------------------
	--
	declare @rootPath int
	--
	SELECT @rootPath = ID
	FROM T_Data_Package_Storage
	WHERE State = 'Active'

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		set @CurrentID = 0
		--
		SELECT @CurrentID = ID,
		       @TeamCurrent = Path_Team
		FROM T_Data_Package
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @CurrentID = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51009
		end
		
		-- Warn if the user is changing the team
		If IsNull(@TeamCurrent, '') <> ''
		Begin
			If @TeamCurrent <> @Team
				Set @TeamChangeWarning = 'Warning: Team changed from "' + @TeamCurrent + '" to "' + @Team + '"; the data package files will need to be moved from the old location to the new one'
		End
		
	end -- mode update

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	If @Mode = 'add'
	begin
		
		If @Name Like '%&%'
		Begin
			-- Replace & with 'and'
			
			If @Name Like '%[a-z0-9]&[a-z0-9]%'
			Begin
				If @Name Like '% %'
					Set @Name = Replace(@Name, '&', ' and ')
				Else
					Set @Name = Replace(@Name, '&', '_and_')
			End
				
			Set @Name = Replace(@Name, '&', 'and')
		End
		
		If @Name Like '%;%'
		Begin
			-- Replace each semicolon with a comma
			Set @Name = Replace(@Name, ';', ',')
		End
		
		-- Make sure the data package name doesn't already exist
		If Exists (SELECT * FROM T_Data_Package WHERE Name = @Name)
		Begin
			set @message = 'Data package name "' + @Name + '" already exists; cannot create an identically named data package'
			RAISERROR (@message, 10, 1)
			return 51010
		End

		INSERT INTO T_Data_Package (
			Name, 
			Package_Type, 
			Description, 
			Comment, 
			Owner, 
			Requester,
			Created, 
			State,
			Package_File_Folder,
			Path_Root,
			Path_Team,
			Mass_Tag_Database,
			Wiki_Page_Link
		) VALUES (
			@Name, 
			@PackageType, 
			@Description, 
			@Comment, 
			@Owner, 
			@Requester,
			getdate(), 
			@State,
			Convert(varchar(64), NewID()),		-- Package_File_Folder cannot be null and must be unique; this guarantees both.  Also, we'll rename it below using dbo.MakePackageFolderName
			@rootPath,
			@Team, 
			@MassTagDatabase,
			IsNull(@PRISMWikiLink, '')
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51011
		end

		-- return ID of newly created entry
		--
		set @ID = IDENT_CURRENT('T_Data_Package')

		---------------------------------------------------
		-- data package folder and wiki page auto naming
		---------------------------------------------------
		--
		set @PkgFileFolder = dbo.MakePackageFolderName(@ID, @Name)
		set @PRISMWikiLink = dbo.MakePRISMWikiPageLink(@ID, @Name)
		--
		UPDATE T_Data_Package
		SET 
			Package_File_Folder = @PkgFileFolder,
			Wiki_Page_Link = @PRISMWikiLink
		WHERE ID = @ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Updating package folder name failed'
			RAISERROR (@message, 10, 1)
			return 51012
		end

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Data_Package 
		SET 
			Name = @Name, 
			Package_Type = @PackageType, 
			Description = @Description, 
			Comment = @Comment, 
			Owner = @Owner, 
			Requester = @Requester,
			Last_Modified = getdate(), 
			State = @State,
			Path_Team = @Team, 
			Mass_Tag_Database = @MassTagDatabase,
			Wiki_Page_Link = @PRISMWikiLink
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed for ID "' + Convert(varchar(12), @ID) + '"'
			RAISERROR (@message, 10, 1)
			return 51013
		end
					
	end -- update mode

	---------------------------------------------------
	-- Create the data package folder when adding a new data package
	---------------------------------------------------
	if @mode = 'add'
		exec @myError = MakeDataPackageStorageFolder @ID, @mode, @message=@message output, @callingUser=@callingUser

	If @TeamChangeWarning <> ''
	Begin
		If IsNull(@message, '') <> ''
			Set @message = @message + '; '
		Else
			Set @message = ': '
			
		Set @message = @message + @TeamChangeWarning
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------

	return @myError



GO
GRANT EXECUTE ON [dbo].[AddUpdateDataPackage] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataPackage] TO [PNL\D3M578] AS [dbo]
GO
