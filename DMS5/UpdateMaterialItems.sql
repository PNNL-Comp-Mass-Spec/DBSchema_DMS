/****** Object:  StoredProcedure [dbo].[UpdateMaterialItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateMaterialItems]
/****************************************************
**
**	Desc:
**	Makes changes for specified list of material items
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	03/27/2008 grk - Initial release (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**			07/24/2008 grk - Added retirement mode
**			09/14/2016 mem - When retiring a single experiment, will abort and update @message if the experiment is already retired
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			11/28/2017 mem - Add support for Reference_Compound
**			               - Only update Container_ID if @mode is 'move_material'
**          10/25/2022 mem - Fix logic bug that used row counts from reference compounds instead of experiments
**
*****************************************************/
(
	@mode varchar(32),			-- 'move_material', 'retire_items'
	@itemList varchar(4096),	-- Either list of material IDs with type tag prefixes (e.g. E:8432,E:8434,E:9786), or list of container IDs (integers)
	@itemType varchar(128),		-- 'mixed_material' or 'containers'
	@newValue varchar(128),
	@comment varchar(512),
    @message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	Declare @myError int = 0
	Declare @myRowCount int = 0

	---------------------------------------------------
	-- Default container to null container
	---------------------------------------------------
	--
	Declare @container varchar(128) = 'na'
	--
	Declare @contID int = 1		-- the null container

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------

	Declare @authorized tinyint = 0
	Exec @authorized = VerifySPAuthorized 'UpdateMaterialItems', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

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
		Declare @contStatus varchar(64)
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

	Declare @material_items as TABLE (
		ID int,
		iType varchar(8),			-- B for Biomaterial, E for Experiment, R for RefCompound
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

	if @itemType = 'mixed_material'
	begin --<mm>
		---------------------------------------------------
		-- Populate temporary table from type-tagged list
		-- of material items, if applicable
		---------------------------------------------------
		--

		-- @itemList is a comma separated list of items of the form Type:ID, for example 'E:8432,E:8434,E:9786'
		-- This is a list of three experiments, IDs 8432, 8434, and 9786

		INSERT INTO @material_items
			(ID, iType)
		SELECT
			substring(Item, 3, 300) as ID,
			substring(Item, 1, 1) as iType		-- B for Biomaterial, E for Experiment, R for RefCompound
		FROM dbo.MakeTableFromList(@itemList)
   		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error populating material item table'
			return 51009
		end

		-- Cache the count of items in temporary table @material_items
		Declare @mixedMaterialCount int = @myRowCount

        Declare @experimentCount int = 0
        
		---------------------------------------------------
		-- Update temporary table with information from
		-- biomaterial entities (if any)
		-- They have iType = 'B'
		---------------------------------------------------
		--
		UPDATE @material_items
		SET iName = V.Name,
		    iContainer = V.Container
		FROM @material_items M
		     INNER JOIN V_Cell_Culture_List_Report_2 V
		       ON V.ID = M.ID
		WHERE M.iType = 'B'
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating material item table with biomaterial information'
			return 51010
		end

		---------------------------------------------------
		-- Update temporary table with information from
		-- experiment entities (if any)
		-- They have iType = 'E'
		---------------------------------------------------
		--
		UPDATE @material_items
		SET iName = V.Experiment,
		    iContainer = V.Container
		FROM @material_items M
		     INNER JOIN V_Experiment_List_Report_2 V
		       ON V.ID = M.ID
		WHERE M.iType = 'E'
       	--
		SELECT @myError = @@error, @experimentCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating material item table with experiment information'
			return 51011
		end

		---------------------------------------------------
		-- Update temporary table with information from
		-- reference compound entities (if any)
		-- They have iType = 'R'
		---------------------------------------------------
		--
		UPDATE @material_items
		SET iName = V.Name,
		    iContainer = V.Container
		FROM @material_items M
		     INNER JOIN V_Reference_Compound_List_Report V
		       ON V.ID = M.ID
		WHERE M.iType = 'R'
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating material item table with reference compound information'
			return 51011
		end

		If @mode = 'retire_items' AND @mixedMaterialCount = 1 AND @experimentCount = 1
		Begin
			-- Retiring a single experiment
			-- Check whether the item being updated is already retired

			Declare @retiredExperiment varchar(128) = ''

			SELECT @retiredExperiment = Experiment_Num
			FROM T_Experiments
			WHERE Exp_ID IN ( SELECT ID
			                  FROM @material_items
			                  WHERE iType = 'E' ) AND
			      EX_Container_ID = @contID AND
			      Ex_Material_Active = 'Inactive'

			If IsNull(@retiredExperiment, '') <> ''
			Begin
				-- Yes, the experiment is already retired

				set @message = 'Experiment is already retired (inactive and no container): ' + @retiredExperiment
				return 51012
			End
		End

	end --<mm>

	if 	@itemType = 'containers'
	begin --<cn>
		---------------------------------------------------
		-- Populate material item list with items contained
		-- by containers given in input list, if applicable
		---------------------------------------------------
		--

		INSERT INTO @material_items
			(ID, iType, iName, iContainer)
		SELECT
			T.Item_ID,
			T.Item_Type,	-- B for Biomaterial, E for Experiment, R for RefCompound
			T.Item,
			T_Material_Containers.Tag
		FROM
			T_Material_Containers INNER JOIN
			(
				SELECT CC_Name AS Item,
				       'B' AS Item_Type,			-- Biomaterial
				       CC_Container_ID AS C_ID,
				       CC_ID AS Item_ID
				FROM T_Cell_Culture
				UNION
				SELECT Experiment_Num AS Item,
				       'E' AS Item_Type,			-- Experiment
				       EX_Container_ID AS C_ID,
				       Exp_ID AS Item_ID
				FROM T_Experiments
				UNION
				SELECT Compound_Name AS Item,
				       'R' AS Item_Type,			-- Reference Compound
				       Container_ID AS C_ID,
				       Compound_ID AS Item_ID
				FROM T_Reference_Compound
			) AS T ON T.C_ID = T_Material_Containers.ID
		WHERE T.C_ID in (SELECT Try_Cast(Item AS int) FROM dbo.MakeTableFromList(@itemList))
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
	Declare @transName varchar(32)
	set @transName = 'UpdateMaterialItems'
	begin transaction @transName

	---------------------------------------------------
	-- Update container reference to destination container
	-- and update material status (if retiring)
	-- for biomaterial items (if any)
	---------------------------------------------------
	--
	UPDATE T_Cell_Culture
	SET CC_Container_ID = CASE
	                          WHEN @mode = 'move_material' THEN @contID
	                          ELSE CC_Container_ID
	                      END,
	    CC_Material_Active = CASE
	                             WHEN @mode = 'retire_items' THEN 'Inactive'
	                             ELSE CC_Material_Active
	                         END
	WHERE CC_ID IN ( SELECT ID FROM @material_items WHERE iType = 'B' )
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
	-- Update container reference to destination container
	-- and update material status (if retiring)
	-- for experiment items (if any)
	---------------------------------------------------
	--
	UPDATE T_Experiments
	SET EX_Container_ID = CASE
	                          WHEN @mode = 'move_material' THEN @contID
	                          ELSE EX_Container_ID
	                      END,
	    Ex_Material_Active = CASE
	                             WHEN @mode = 'retire_items' THEN 'Inactive'
	                             ELSE Ex_Material_Active
	                         END

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
	-- Update container reference to destination container
	-- for reference compounds (if any)
	---------------------------------------------------
	--
	UPDATE T_Reference_Compound
	SET Container_ID = CASE
	                       WHEN @mode = 'move_material' THEN @contID
	                       ELSE Container_ID
	                   END,
	    Active = CASE
	                 WHEN @mode = 'retire_items' THEN 0
	                 ELSE Active
	             END
	WHERE Compound_ID IN (SELECT ID FROM @material_items WHERE iType = 'R')
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating container reference for reference compounds'
		return 51010
	end

	---------------------------------------------------
	-- Set up appropriate label for log
	---------------------------------------------------

	Declare @moveType varchar(128) = '??'

	if @mode = 'retire_items'
		set @moveType = 'Material Retirement'
	else
	if @mode = 'move_material'
		set @moveType = 'Material Move'

	---------------------------------------------------
	-- Make log entries
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
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialItems] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMaterialItems] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialItems] TO [Limited_Table_Write] AS [dbo]
GO
