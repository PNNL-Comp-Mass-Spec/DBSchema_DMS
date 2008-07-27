/****** Object:  StoredProcedure [dbo].[UpdateMaterialContainers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateMaterialContainers
/****************************************************
**
**	Desc: 
**	Makes changes for specified list of containers
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 03/26/2008     - (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**    
*****************************************************/
	@mode varchar(32), -- 'move_container', 'retire_container', 'retire_container_and_contents'
	@containerList varchar(4096),
	@newValue varchar(128),
	@comment varchar(512),
    @message varchar(512) output,
   	@callingUser varchar(128) = ''
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	---------------------------------------------------
	-- temporary table to hold containers
	---------------------------------------------------

	declare @material_container_list TABLE (
		ID int,
		iName varchar(128),
		iLocation varchar(64),
		iItemCount int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary table'
		return 51007
	end

	---------------------------------------------------
	-- populate temporary table from container list
	---------------------------------------------------
	
	INSERT INTO @material_container_list
		(ID, iName, iLocation, iItemCount)
	SELECT 
	  #ID, Container, Location, Items
	FROM   
	  V_Material_Containers_List_Report
	WHERE #ID IN (
			SELECT Item
			FROM dbo.MakeTableFromList(@containerList)
			)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary table'
		return 51009
	end

	-- remember how many containers are in the list
	--
	declare @numContainers int
	set @numContainers = @myRowCount

	---------------------------------------------------
	-- resolve location to ID (according to mode)
	---------------------------------------------------
	--
	declare @location varchar(128)
	set @location = 'None' -- the null location
	--
	declare @locID int
	set @locID = 1  -- the null location
	--
	if @mode = 'move_container'
	begin --<c>
		set @location = @newValue
		set @locID = 0
		--
		declare @contCount int
		declare @locLimit int
		declare @locStatus varchar(64)
		--
		set @contCount = 0
		set @locLimit = 0
		set @locStatus = ''
		--
		SELECT 
			@locID = #ID, 
			@contCount = Containers,
			@locLimit = Limit, 
			@locStatus = Status
		FROM  V_Material_Locations_List_Report
		WHERE Location = @location
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Could not resove location name "' + @location + '" to ID'
			return 510019
		end
		--
		if @locID = 0
		begin
			set @message = 'Destination location "' + @location + '" could not be found in database'
			return 510019
		end

		---------------------------------------------------
		-- is location suitable?
		---------------------------------------------------
		
		if @locStatus <> 'Active'
		begin
			set @message = 'Location "' + @location + '" is not in the "Active" state'
			return 510021
		end

		if @contCount + @numContainers > @locLimit
		begin
			set @message = 'The maximum container capacity (' + cast(@locLimit as varchar(12)) + ') of location "' + @location + '" would be exceeded by the move'
			return 510023
		end

	end --<c>

	---------------------------------------------------
	-- determine whether or not any containers have contents
	---------------------------------------------------
	declare @c int
	set @c = 1
	--
	SELECT @c = count(*)
	FROM @material_container_list
	WHERE iItemCount > 0

	---------------------------------------------------
	-- error if contents and 'plain' container retirement
	---------------------------------------------------
	--
	if @mode = 'retire_container' AND @c > 0
	begin
		set @message = 'All containers must be empty in order to retire them'
		return 510021
	end

	---------------------------------------------------
	-- retire contents if 'contents' container retirement
	---------------------------------------------------
	if @mode = 'retire_container_and_contents' AND @c > 0
	begin
		exec @myError = UpdateMaterialItems
				'retire_items',
				@containerList,
				'containers',
				'',
				@comment,
				@message output,
				@callingUser

		if @myError <> 0
			return @myError
	end
--debug
/*
select 'UpdateMaterialContainers' as Sproc, @mode as Mode, convert(char(22), @newValue) as Parameter, convert(char(12), @locID) as LocationID, @containerList as Containers
select * from @material_container_list
return 0
*/
	---------------------------------------------------
	-- start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'UpdateMaterialContainers'
	begin transaction @transName

	---------------------------------------------------
	-- update containers to be at new location
	---------------------------------------------------
	
	UPDATE T_Material_Containers
	SET 
		Location_ID = @locID,
		Status = CASE WHEN @mode = 'retire_container' OR @mode = 'retire_container_and_contents'THEN 'Inactive' ELSE Status END
	WHERE ID IN (SELECT ID FROM @material_container_list)
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating location reference'
		return 51010
	end

	---------------------------------------------------
	-- set up appropriate label for log
	---------------------------------------------------

	declare @moveType varchar(128)
	set @moveType = '??'

	if @mode = 'retire_container' or @mode = 'retire_container_and_contents'
		set @moveType = 'Container Retirement'
	else
	if @mode = 'move_container'
		set @moveType = 'Container Move'


	---------------------------------------------------
	-- make log entries
	---------------------------------------------------
	--
	INSERT INTO T_Material_Log (
		Type, 
		Item, 
		Initial_State, 
		Final_State, 
		User_PRN,
		Comment
	) 
	SELECT 
		@moveType,
		iName,
		iLocation,
		@location,
		@callingUser,
		@comment
	FROM @material_container_list
	WHERE iLocation <> @location
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error making log entries'
		return 51010
	end

	commit transaction @transName

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateMaterialContainers] TO [DMS2_SP_User]
GO
