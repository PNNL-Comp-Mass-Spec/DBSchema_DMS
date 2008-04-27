/****** Object:  StoredProcedure [dbo].[AddUpdateMaterialContainer] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateMaterialContainer
/****************************************************
**
**  Desc: Adds new or edits an existing material container
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/20/2008
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
	@Container varchar(128) output,
	@Type varchar(32),
	@Location varchar(24),
	@Status varchar(32),
	@Comment varchar(1024),
	@Barcode varchar(32),
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
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated


	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @containerID int
	set @containerID = 0
	--
	declare @curLocationID int
	set @curLocationID = 0
	--
	declare @curType varchar(32)
	set @curType = ''
	--
	declare @curStatus varchar(32)
	set @curStatus = ''
	--
	SELECT 
		@containerID = ID,
		@curLocationID = Location_ID,
		@curType = Type, 
		@curStatus = Status
	FROM  T_Material_Containers
	WHERE (Tag = @Container)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for existing entry'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	if @mode = 'add' and @containerID <> 0
	begin
		set @message = 'Cannot add container with same name as existing container'
		RAISERROR (@message, 10, 1)
		return 51002
	end

	if @mode = 'update' and @containerID = 0
	begin
		set @message = 'No entry could be found in database for update'
		RAISERROR (@message, 10, 1)
		return 51003
	end

	---------------------------------------------------
	-- resolve input location name to ID
	---------------------------------------------------
	declare @LocationID int
	set @LocationID = 0
	--
	SELECT @LocationID = ID
	FROM T_Material_Locations
	WHERE Tag = @Location	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving location ID'
		RAISERROR (@message, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- Resolve current Location id to name
	---------------------------------------------------
	declare @curLocationName varchar(125)
	set @curLocationName = ''
	--
	SELECT @curLocationName = Tag 
	FROM T_Material_Locations 
	WHERE ID = @curLocationID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving name of current Location'
		RAISERROR (@message, 10, 1)
		return 510027
	end
	
	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		-- future: accept '<next bag>' or '<next box> and generate container name
	
		INSERT INTO T_Material_Containers (
			Tag, 
			Type, 
			Comment, 
			Barcode, 
			Location_ID, 
			Status
		) VALUES (
			@Container, 
			@Type, 
			@Comment, 
			@Barcode, 
			@LocationID, 
			@Status
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

		--  material movement logging
		--	
		exec PostMaterialLogEntry
			'Container Status',
			@Container,
			'na',
			'Active',
			@callingUser,
			'Container created'

		exec PostMaterialLogEntry
			'Container Move',
			@Container,
			'na',
			@Location,
			@callingUser,
			'Container created'

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Material_Containers 
		SET 
			Type = @Type, 
			Comment = @Comment, 
			Barcode = @Barcode, 
			Location_ID = @LocationID, 
			Status = @Status
		WHERE (Tag = @Container)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @Container + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end

		--  material movement logging
		--	
		if @curStatus <> @Status
		begin
			exec PostMaterialLogEntry
				'Container Status',
				@Container,
				@curStatus,
				@Status,
				@callingUser,
				'Container updated'
		end

		if @curLocationName <> @Location
		begin
			exec PostMaterialLogEntry
				'Container Move',
				@Container,
				@curLocationName,
				@Location,
				@callingUser,
				'Container updated'
		end

	end -- update mode

	return @myError


GO
