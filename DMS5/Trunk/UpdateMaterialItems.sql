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
**		Date: 03/27/2008     - (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**    
*****************************************************/
	@mode varchar(32), -- 
	@itemList varchar(4096),
	@itemType varchar(128),
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
	-- Resolve container name to ID
	---------------------------------------------------

	declare @container varchar(128)
	set @container = @newValue
	--
	declare @contID int
	set @contID = 0
	--
	declare @contStatus varchar(64)
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

	---------------------------------------------------
	-- temporary table to hold items
	---------------------------------------------------

	CREATE TABLE #TD (
		ID int,
		iName varchar(128),
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
	-- populate temporary table
	---------------------------------------------------

	---------------------------------------------------
	-- if type is biomaterial
	--
	if @itemType = 'material_move_biomaterial'
	begin --<c>
		INSERT INTO [#TD]
			(ID, iName, iContainer)
		SELECT ID, [Name], Container
		FROM V_Cell_Culture_List_Report_2
		WHERE ID IN (
			SELECT Item
			FROM dbo.MakeTableFromList(@itemList)
			)
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error populating temporary table'
			return 51009
		end
	end  --<c>

	---------------------------------------------------
	-- if type is experiment
	--
	if @itemType = 'material_move_experiment'
	begin --<d>
		INSERT INTO [#TD]
			(ID, iName, iContainer)
		SELECT ID, Experiment, Container
		FROM V_Experiment_List_Report_2
		WHERE ID IN (
			SELECT Item
			FROM dbo.MakeTableFromList(@itemList)
			)
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error populating temporary table'
			return 51009
		end
	end  --<d>
	
	---------------------------------------------------
	-- Move items
	---------------------------------------------------

	declare @moveType varchar(128)
	set @moveType = '??'

	---------------------------------------------------
	-- Move biomaterial items
	---------------------------------------------------

	---------------------------------------------------
	-- start transaction
	--
	declare @transName varchar(32)
	set @transName = 'UpdateMaterialItems'
	begin transaction @transName

	---------------------------------------------------
	-- update container reference to destination container
	--
	if @itemType = 'material_move_biomaterial'
	begin --<a>
		set @moveType = 'Biomaterial Move'
		--
		UPDATE T_Cell_Culture
		SET CC_Container_ID = @contID
		WHERE CC_ID IN (SELECT ID FROM #TD)
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating container reference'
			return 51010
		end
	end --<a>
	--
	if @itemType = 'material_move_experiment'
	begin --<b>
		set @moveType = 'Experiment Move'
		--	
		UPDATE T_Experiments
		SET EX_Container_ID = @contID
		WHERE Exp_ID IN (SELECT ID FROM #TD)
       	--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating container reference'
			return 51010
		end
	end --<b>

	---------------------------------------------------
	-- make log entries
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
		iContainer,
		@container,
		@callingUser,
		@comment
	FROM #TD
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
