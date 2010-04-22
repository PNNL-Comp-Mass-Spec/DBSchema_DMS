/****** Object:  StoredProcedure [dbo].[CopyAuxInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.CopyAuxInfo
/****************************************************
**
**	Desc: 
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		01/27/2003 grk - Initial release
**      07/12/2008 grk - Added error check for source
**    
*****************************************************/
	@targetName varchar(128),
	@targetEntityName varchar(128),
	@categoryName varchar(128), 
	@subCategoryName varchar(128), 
	@sourceEntityName varchar(128),
	@mode varchar(24),
	@message varchar(512) output
AS
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
	if @targetEntityName = @sourceEntityName
	begin
		set @msg = 'Target and source cannot be the same'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

	-- future

	---------------------------------------------------
	-- Resolve target name to target table criteria
	---------------------------------------------------

	declare @tgtTableName varchar(128)
	declare @tgtTableNameCol varchar(128)
	declare @tgtTableIDCol varchar(128)

	SELECT 
		@tgtTableName = Target_Table, 
		@tgtTableIDCol = Target_ID_Col, 
		@tgtTableNameCol = Target_Name_Col
	FROM T_AuxInfo_Target
	WHERE (Name = @targetName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @msg = 'Could not look up table criteria for target: "' + @targetName + '"'
		RAISERROR (@msg, 10, 1)
		return 51000
	end

	---------------------------------------------------
	-- Resolve target name and destination entity name to entity ID
	---------------------------------------------------

	declare @targetID int
	set @targetID = 0
	
	declare @sql nvarchar(1024)
	
	set @sql = N'' 
	set @sql = @sql + 'SELECT @targetID = ' + @tgtTableIDCol
	set @sql = @sql + ' FROM ' + @tgtTableName
	set @sql = @sql + ' WHERE ' + @tgtTableNameCol
	set @sql = @sql + ' = ''' + @targetEntityName + ''''
	
	exec sp_executesql @sql, N'@targetID int output', @targetID = @targetID output

	if @targetID = 0
	begin
		set @msg = 'Could not find "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		return 51000
	end

	declare @destEntityID int
	set @destEntityID = @targetID

	---------------------------------------------------
	-- Resolve target name and source entity name to entity ID
	---------------------------------------------------

	set @targetID = 0

	set @sql = N'' 
	set @sql = @sql + 'SELECT @targetID = ' + @tgtTableIDCol
	set @sql = @sql + ' FROM ' + @tgtTableName
	set @sql = @sql + ' WHERE ' + @tgtTableNameCol
	set @sql = @sql + ' = ''' + @sourceEntityName + ''''
	
	exec sp_executesql @sql, N'@targetID int output', @targetID = @targetID output

	if @targetID = 0
	begin
		set @msg = 'Could not find "' + @sourceEntityName + '"'
		RAISERROR (@msg, 10, 1)
		return 51000
	end

	declare @sourceEntityID int
	set @sourceEntityID = @targetID

	
	---------------------------------------------------
	-- copy existing values in aux info table
	-- for given target name and category
	-- from given source target entity
	-- to given destination entity
	---------------------------------------------------

	declare @transName varchar(32)

if @mode = 'copyCategory'
begin
	-- Start transaction
	--
	set @transName = 'CopyAuxInfo-copyCategory'
	begin transaction @transName
	
	-- delete any existing values
	--
	Delete From T_AuxInfo_Value
	WHERE (Target_ID = @destEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName) AND 
		        (Category = @categoryName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Delete failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51001
	end

	-- insert new values
	--
	INSERT INTO T_AuxInfo_Value
	   (Target_ID, AuxInfo_ID, Value)
	SELECT @destEntityID AS Target_ID, AuxInfo_ID, Value
	FROM T_AuxInfo_Value
	WHERE (Target_ID = @sourceEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName) AND 
		        (Category = @categoryName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Insert failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51000
	end
	commit transaction @transName
end

	---------------------------------------------------
	-- copy existing values in aux info table
	-- for given target name and category and subcategory
	-- from given source target entity
	-- to given destination entity
	---------------------------------------------------

if @mode = 'copySubcategory'
begin
	-- Start transaction
	--
	set @transName = 'CopyAuxInfo-copySubcategory'
	begin transaction @transName
	
	-- delete any existing values
	--
	Delete from T_AuxInfo_Value
	WHERE (Target_ID = @destEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName) AND 
		        (Category = @categoryName) AND 
		        (Subcategory = @subCategoryName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Delete failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51001
	end

	-- insert new values
	--
	INSERT INTO T_AuxInfo_Value
	   (Target_ID, AuxInfo_ID, Value)
	SELECT @destEntityID AS Target_ID, AuxInfo_ID, Value
	FROM T_AuxInfo_Value
	WHERE (Target_ID = @sourceEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName) AND 
		        (Category = @categoryName) AND 
		        (Subcategory = @subCategoryName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Insert failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51000
	end
	commit transaction @transName
end

	---------------------------------------------------
	-- copy existing values in aux info table
	-- for given target name 
	-- from given source target entity
	-- to given destination entity
	---------------------------------------------------

if @mode = 'copyAll'
begin
	-- Start transaction
	--
	set @transName = 'CopyAuxInfo-copyAll'
	begin transaction @transName
	
	-- delete any existing values
	--
	Delete from T_AuxInfo_Value
	WHERE (Target_ID = @destEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Delete failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51001
	end

	--
	INSERT INTO T_AuxInfo_Value
	   (Target_ID, AuxInfo_ID, Value)
	SELECT @destEntityID AS Target_ID, AuxInfo_ID, Value
	FROM T_AuxInfo_Value
	WHERE (Target_ID = @sourceEntityID) 
	AND (AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Insert failed for copy into target: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		rollback transaction @transName
		return 51000
	end
	commit transaction @transName
end


	---------------------------------------------------
	-- 
	---------------------------------------------------

	return 0

GO
GRANT EXECUTE ON [dbo].[CopyAuxInfo] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CopyAuxInfo] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyAuxInfo] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyAuxInfo] TO [PNL\D3M580] AS [dbo]
GO
