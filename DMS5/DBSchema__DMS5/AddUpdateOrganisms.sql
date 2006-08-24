/****** Object:  StoredProcedure [dbo].[AddUpdateOrganisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE AddUpdateOrganisms
/****************************************************
**
**  Desc: Adds new or edits existing Organisms
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/07/2006
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @orgName varchar(50),
  @orgShortName varchar(128),
  @orgDBPath varchar(255),
  @orgDBLocalPath varchar(255),
  @orgStorageLocation varchar(256),
  @orgDBName varchar(64),
  @orgDescription varchar(256),
  @orgDomain varchar(64),
  @orgKingdom varchar(64),
  @orgPhylum varchar(64),
  @orgClass varchar(64),
  @orgOrder varchar(64),
  @orgFamily varchar(64),
  @orgGenus varchar(128),
  @orgSpecies varchar(128),
  @orgStrain varchar(128),
  @orgDNATransTabID varchar(6), 
  @orgMitoDNATransTabID varchar(6),
  @ID int output,
  @mode varchar(12) = 'add', -- or 'update'
  @message varchar(512) output
As
  set nocount on

  declare @myError int
  set @myError = 0

  declare @myRowCount int
  set @myRowCount = 0
 
  set @message = ''

  declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@orgName) < 1
	begin
		set @myError = 51000
		RAISERROR ('organism Name was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

    declare @tmp int
	set @tmp = 0

	-- cannot create an entry that already exists
	--
	if @mode = 'add'
	begin
		execute @tmp = GetOrganismID @orgName
		if @tmp <> 0 
		begin
			set @msg = 'Cannot add: Organism "' + @orgName + '" already in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end

	-- cannot update a non-existent entry
	--
	declare @nm varchar(50)
	if @mode = 'update'
	begin
		--
		SELECT @tmp = Organism_ID, @nm = OG_name
		FROM  T_Organisms
		WHERE (Organism_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @tmp = 0 
		begin
			set @msg = 'Cannot update: Organism "' + @orgName + '" is not in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		--
		if @nm <> @orgName 
		begin
			set @msg = 'Cannot update: Organism name may not be changed '
			RAISERROR (@msg, 10, 1)
			return 51005
		end
	end
	
	---------------------------------------------------
	-- resolve DNA translation table IDs
	---------------------------------------------------
	declare @iOrgDNATransTabID int
	set @iOrgDNATransTabID = Null
	if @orgDNATransTabID <> ''
	begin
		set @iOrgDNATransTabID = convert(int, @orgDNATransTabID)
	end
	--
	declare @iOrgMitoDNATransTabID int
	set @iOrgMitoDNATransTabID = null
	if @orgMitoDNATransTabID <> ''
	begin
		set @iOrgMitoDNATransTabID = convert(int, @orgMitoDNATransTabID)
	end
	--

  ---------------------------------------------------
  -- action for add mode
  ---------------------------------------------------
  if @Mode = 'add'
  begin
 
  INSERT INTO T_Organisms (
    OG_name, 
    OG_organismDBPath, 
    OG_organismDBLocalPath, 
    OG_organismDBName, 
    OG_created, 
    OG_description, 
    OG_Short_Name, 
    OG_Storage_Location, 
    OG_Domain, 
    OG_Kingdom, 
    OG_Phylum, 
    OG_Class, 
    OG_Order, 
    OG_Family, 
    OG_Genus, 
    OG_Species, 
    OG_Strain,
    OG_DNA_Translation_Table_ID, 
    OG_Mito_DNA_Translation_Table_ID
  ) VALUES (
    @orgName, 
    @orgDBPath, 
    @orgDBLocalPath, 
    @orgDBName, 
    getdate(), 
    @orgDescription, 
    @orgShortName, 
    @orgStorageLocation, 
    @orgDomain, 
    @orgKingdom, 
    @orgPhylum, 
    @orgClass, 
    @orgOrder, 
 @orgFamily, 
    @orgGenus, 
    @orgSpecies, 
    @orgStrain,
    @iOrgDNATransTabID, 
    @iOrgMitoDNATransTabID
  )
 /**/
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Insert operation failed'
      RAISERROR (@message, 10, 1)
      return 51007
    end
    
    -- return IDof newly created entry
    --
    set @ID = IDENT_CURRENT('T_Organisms')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Organisms 
    SET 
      OG_name = @orgName, 
      OG_organismDBPath = @orgDBPath, 
      OG_organismDBLocalPath = @orgDBLocalPath, 
      OG_organismDBName = @orgDBName, 
      OG_description = @orgDescription, 
      OG_Short_Name = @orgShortName, 
      OG_Storage_Location = @orgStorageLocation, 
      OG_Domain = @orgDomain, 
      OG_Kingdom = @orgKingdom, 
      OG_Phylum = @orgPhylum, 
      OG_Class = @orgClass, 
      OG_Order = @orgOrder, 
      OG_Family = @orgFamily, 
      OG_Genus = @orgGenus, 
      OG_Species = @orgSpecies, 
      OG_Strain = @orgStrain,
      OG_DNA_Translation_Table_ID = @iOrgDNATransTabID, 
      OG_Mito_DNA_Translation_Table_ID = @iOrgMitoDNATransTabID
    WHERE (Organism_ID = @ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Update operation failed: "' + @ID + '"'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end -- update mode

  return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganisms] TO [DMS_Org_Database_Admin]
GO
