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
	@mode varchar(32), -- 
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
	
	declare @transName varchar(32)
	set @transName = 'UpdateMaterialContainers'

	---------------------------------------------------
	---------------------------------------------------
	-- common actions
	---------------------------------------------------
	---------------------------------------------------

	---------------------------------------------------
	-- temporary table to hold containers
	---------------------------------------------------

	CREATE TABLE #TD (
		ID int,
		iName varchar(128),
		iLocation varchar(64) NULL,
		iStatus varchar(64) NULL,
		iItemCount int NULL
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
	
	INSERT INTO [#TD]
		(ID, iName, iLocation, iStatus, iItemCount)
	SELECT 
	  #ID, Container, Location, Status, Items
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
	---------------------------------------------------
	-- status change
	---------------------------------------------------
	---------------------------------------------------

	if @mode = 'status'
	begin --<status>
		set @message = '|' + @mode + '|' + @containerList + '|' + @newValue + '|' + @comment + '|'  

		declare @status varchar(64)
		set @status = @newValue

		---------------------------------------------------
		-- make sure containers are empty if setting inactive
		---------------------------------------------------
		if @status <> 'Active'
		begin
			declare @c int
			set @c = 1
			--
			SELECT @c = count(*)
			FROM #TD
			WHERE iItemCount > 0
			--
			if @c > 0
			begin
				set @message = 'All containers must be empty in order to be set to inactive'
				return 510021
			end
		end

		---------------------------------------------------
		-- start transaction
		---------------------------------------------------
		--
		begin transaction @transName


		---------------------------------------------------
		-- update status of containers
		---------------------------------------------------
		
		UPDATE T_Material_Containers
		SET Status = @status
		WHERE ID IN (SELECT ID FROM #TD)
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
			'Container Status',
			iName,
			iStatus,
			@status,
			@callingUser,
			@comment
		FROM #TD
		WHERE iStatus <> @status
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

	end --<status>

	---------------------------------------------------
	---------------------------------------------------
	-- container movement
	---------------------------------------------------
	---------------------------------------------------

	if @mode = 'move_container'
	begin --<move_container>

		---------------------------------------------------
		-- resolve location to ID
		---------------------------------------------------
		declare @location varchar(128)
		set @location = @newValue
		--
		declare @locID int
		set @locID = 0
		--
		declare @contCount int
		declare @locLimit int
		declare @locStatus varchar(64)
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

		---------------------------------------------------
		-- start transaction
		---------------------------------------------------
		--
		begin transaction @transName

		---------------------------------------------------
		-- update containers to be at new location
		---------------------------------------------------
		
		UPDATE T_Material_Containers
		SET Location_ID = @locID
		WHERE ID IN (SELECT ID FROM #TD)
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
			'Container Move',
			iName,
			iLocation,
			@location,
			@callingUser,
			@comment
		FROM #TD
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

	end --<move_container>


	return @myError

GO
