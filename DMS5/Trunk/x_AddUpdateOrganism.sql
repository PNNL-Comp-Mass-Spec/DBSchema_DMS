/****** Object:  StoredProcedure [dbo].[x_AddUpdateOrganism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.x_AddUpdateOrganism
/****************************************************
**
**  ###-------------------------------------------###
**  ### Deemed unused in October 2007             ###
**  ### http://prismtrac.pnl.gov/trac/ticket/562  ###
**  ###-------------------------------------------###
**
**	Desc: Adds new or updates existing organisms in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@organismName  unique name for the new organism
**	
**
**		Auth: jds
**		Date: 6/16/2004
**    
*****************************************************/
(
	@organismName varchar(50), 
	@organismDbPath varchar(255), 
	@organismLocDbPath varchar(255), 
	@organismDbName varchar(64), 
	@organismDescription varchar(50),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
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
	if LEN(@OrganismName) < 1
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

	declare @organismID int
	set @organismID = 0
	--
	execute @organismID = GetOrganismID @OrganismName

	-- cannot create an entry that already exists
	--
	if @organismID <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Organism "' + @organismName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @organismID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Organism "' + @OrganismName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Organisms (
			OG_Name, 
			OG_organismDBPath, 
			OG_organismDBLocalPath, 
			OG_organismDBName, 
			OG_created, 
			OG_Description
		) VALUES (
			@organismName, 
			@organismDbPath, 
			@organismLocDbPath, 
			@organismDbName, 
			GETDATE(), 
			@organismDescription
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @organismName + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
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
		UPDATE T_Organisms 
		SET 
			OG_organismDBPath = @organismDbPath, 
			OG_organismDBLocalPath = @organismLocDbPath, 
			OG_organismDBName = @organismDbName, 
			OG_Description = @organismDescription 
		WHERE (OG_Name = @organismName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @organismName + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[x_AddUpdateOrganism] TO [DMS_Org_Database_Admin]
GO
