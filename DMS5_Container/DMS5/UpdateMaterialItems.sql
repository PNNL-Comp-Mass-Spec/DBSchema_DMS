/****** Object:  StoredProcedure [dbo].[UpdateMaterialItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateMaterialItems
/****************************************************
**
**	Desc: 
**	Makes changes for specified list of material items
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 03/27/2008  grk - Initial release (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**		Date: 07/24/2008  grk - Added retirement mode
**    
*****************************************************/
	@mode varchar(32), -- 'move_material', 'retire_items'
	@itemList varchar(4096), -- either list of material IDs with type tag prefixes, or list of containers
	@itemType varchar(128), -- 'mixed_material', 'containers'
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
	-- Default container to null container
	---------------------------------------------------
	--
	declare @container varchar(128)
	set @container = 'na'
	--
	declare @contID int
	set @contID = 1  -- the null container
	
	---------------------------------------------------
	-- Resolve container name to actual ID (if applicable)
	---------------------------------------------------
	--
	if @mode = 'move_material' AND @newValue = ''
	begin
		set @message = 'No destination container was provided'
		return 51021
	end

	if @mode = 'move_material'
	begin --<a>
		--
		declare @contStatus varchar(64)
		set @container = @newValue
		set @contID = 0
		--
		SELECT 
			@contID = ID,
			@contStatus = Status
		FROM T_Material_Containers
		WHERE Tag = @container
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Could not resove container name "' + @container + '" to ID'
			return 510019
		end
		--
		if @contID = 0
		begin
			set @message = 'Destination container "' + @container + '" could not be found in database'
			return 510019
		end
		
		---------------------------------------------------
		-- is container a valid target?
		---------------------------------------------------
		if @contStatus <> 'Active'
		begin
			set @message = 'Container "' + @container + '" must be in "Active" state to receive material'
			return 510007
		end
	end --<a>

	---------------------------------------------------
	-- temporary table to hold material items
	---------------------------------------------------

	declare @material_items as TABLE (
		ID int,
		iType varchar(8),
		iName varchar(128) NULL,
		iContainer varchar(64) NULL
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
	-- populate temporary table from type-tagged list
	-- of material items, if applicable
	---------------------------------------------------
	--
	if @itemType = 'mixed_material'
	begin --<mm>
	
		INSERT INTO @material_items
			(ID, iType)
		SELECT 
			substring(Item, 3, 300) as ID, 
			substring(Item, 1, 1) as iType
		FROM dbo.MakeTableFromList(@itemList)
   		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error populating material item table'
			return 51009
		end

		---------------------------------------------------
		-- update temporary table with information from
		-- biomaterial entities (if any)
		---------------------------------------------------
		--
		update @material_items
		set
			iName = V.Name,
			iContainer = V.Container
		from
			@material_items M inner join V_Cell_Culture_List_Report_2 V
			on V.ID = M.ID
			where M.iType = 'B'
       		--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error updating material item table with biomaterial information'
				return 51010
			end

		---------------------------------------------------
		-- update temporary table with information from
		-- experiment entities (if any)
		---------------------------------------------------
		--
		update @material_items
		set
			iName = V.Experiment,
			iContainer = V.Container
		from
			@material_items M inner join V_Experiment_List_Report_2 V
			on V.ID = M.ID
			where M.iType = 'E'
       		--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error updating material item table with experiment information'
				return 51011
			end
	end --<mm>

	---------------------------------------------------
	-- populate material item list with items contained
	-- by containers given in input list, if applicable
	---------------------------------------------------
	--
	if 	@itemType = 'containers'
	begin --<cn>
		INSERT INTO @material_items
			(ID, iType, iName, iContainer)
		SELECT
			T.Item_ID AS ID, 
			SUBSTRING(T.Item_Type, 1, 1) AS iType, 
			T.Item AS iName, 
			T_Material_Containers.Tag AS iContainer
		FROM
			T_Material_Containers INNER JOIN
			(
				SELECT 
				  T_Cell_Culture_1.CC_Name       AS Item,
				  'Biomaterial'                  AS Item_Type,
				  T_Cell_Culture.CC_Container_ID AS C_ID,
				  T_Cell_Culture.CC_ID           AS Item_ID
				FROM   
				  T_Cell_Culture
				  INNER JOIN T_Cell_Culture AS T_Cell_Culture_1
					ON T_Cell_Culture.CC_ID = T_Cell_Culture_1.CC_ID
				UNION
				SELECT 
				  T_Experiments_1.Experiment_Num AS Item,
				  'Experiment'                   AS Item_Type,
				  T_Experiments.EX_Container_ID  AS C_ID,
				  T_Experiments.Exp_ID           AS Item_ID
				FROM   
				  T_Experiments
				  INNER JOIN T_Experiments AS T_Experiments_1
					ON T_Experiments.Exp_ID = T_Experiments_1.Exp_ID
			) AS T ON T.C_ID = T_Material_Containers.ID
		WHERE T.C_ID in (SELECT Convert(int, Item) FROM dbo.MakeTableFromList(@itemList))
       		--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error populating material item table from container list'
				return 51025
			end
	end --<cn>

-- debug
/*
select 'UpdateMaterialItems' as Sproc, @mode as Mode, CASE WHEN @mode = 'retire_items' THEN 'Inactive' ELSE '(unchanged)' END as Status, @contID as Container
select * from @material_items
return @myError
*/

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'UpdateMaterialItems'
	begin transaction @transName

	---------------------------------------------------
	-- update container reference to destination container
	-- and update material status (if retiring)
	-- for biomaterial items (if any)
	---------------------------------------------------
	--
	UPDATE T_Cell_Culture
	SET 
		CC_Container_ID = @contID,
		CC_Material_Active = CASE WHEN @mode = 'retire_items' THEN 'Inactive' ELSE CC_Material_Active END
	WHERE CC_ID IN (SELECT ID FROM @material_items WHERE iType = 'B')
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating container reference for biomaterial'
		return 51010
	end

	---------------------------------------------------
	-- update container reference to destination container
	-- and update material status (if retiring)
	-- for experiment items (if any)
	---------------------------------------------------
	--
	UPDATE T_Experiments
	SET 
		EX_Container_ID = @contID,
		Ex_Material_Active = CASE WHEN @mode = 'retire_items' THEN 'Inactive' ELSE Ex_Material_Active END
	WHERE Exp_ID IN (SELECT ID FROM @material_items WHERE iType = 'E')
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating container reference for experiments'
		return 51010
	end

	---------------------------------------------------
	-- set up appropriate label for log
	---------------------------------------------------

	declare @moveType varchar(128)
	set @moveType = '??'

	if @mode = 'retire_items'
		set @moveType = 'Material Retirement'
	else
	if @mode = 'move_material'
		set @moveType = 'Material Move'

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
		iType + ' ' + @moveType,
		iName,
		iContainer,
		@container,
		@callingUser,
		@comment
	FROM @material_items
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error making log entries'
		return 51011
	end

	commit transaction @transName

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateMaterialItems] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialItems] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialItems] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialItems] TO [PNL\D3M580] AS [dbo]
GO
