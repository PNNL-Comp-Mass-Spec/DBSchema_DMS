/****** Object:  StoredProcedure [dbo].[AddUpdateAuxInfoDefinition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure AddUpdateAuxInfoDefinition
/****************************************************
**
**	Desc: 
**	Adds new or updates definition of 
**	auxiliary information in database
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 4/19/2002
**    
*****************************************************/
(
	@mode varchar(32) = 'UpdateItem', -- 'AddTarget', 'AddCategory', 'AddSubcategory', 'AddItem', 'AddAllowedValue'
	@targetName varchar(128) = 'Cell Culture',
	@categoryName varchar(128) = 'Prokaryote', 
	@subCategoryName varchar(128) = 'Starter Culture Conditions', 
	@itemName varchar(128) = 'Date Started',
	@seq int = 1,
	@param1 varchar(128) = '',
	@param2 varchar(128) = '',
	@param3 varchar(128) = '',
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @parentID int
	declare @tmpSeq int
	declare @tmpID int
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future


	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'AddTarget'
	begin
		-- future: verify correctness of 
		-- Target_Table, Target_ID_Col, Target_Name_Col
	
		-- is target already in table?
		--
		set @tmpID = 0
		--
		SELECT @tmpID = ID
		FROM T_AuxInfo_Target
		WHERE (Name = @TargetName)
   		--
		if @tmpID <> 0
		begin
			set @msg = 'Cannot add: target already exists'
			RAISERROR (@msg, 10, 1)
			return 51000
		end

		-- insert new target into table
		--
		INSERT INTO T_AuxInfo_Target
		   (Name, Target_Table, Target_ID_Col, Target_Name_Col)
		VALUES (@TargetName, @Param1, @Param2, @Param3)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert target failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	
	end -- mode 'AddTarget'

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'AddCategory'
	begin
		-- resolve parent names to ID
		--
		set @parentID = 0
		--
		SELECT @parentID = ID
		FROM T_AuxInfo_Target
		WHERE (Name = @TargetName)
		--
		if @parentID = 0
		begin
			set @msg = 'Could not resolve parent ID'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- is category already in table?
		--
		set @tmpID = 0
		--
		SELECT @tmpID = ID
		FROM T_AuxInfo_Category
		WHERE (Target_Type_ID = @parentID) AND (Name = @categoryName)
   		--
		if @tmpID <> 0
		begin
			set @msg = 'Cannot add: category already exists for this target'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- calculate new sequence
		--
		set @tmpSeq = 0
		--
		SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
		FROM T_AuxInfo_Category
		WHERE (Target_Type_ID = @parentID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		-- future: check error?
		--
		set @tmpSeq = @tmpSeq + 1
		
		-- insert new category for parent
		--
		INSERT INTO T_AuxInfo_Category
		   (Name, Target_Type_ID, Sequence)
		VALUES (@categoryName, @parentID, @tmpSeq)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert category failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	end -- mode 'AddCategory'

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'AddSubcategory'
	begin
		-- resolve parent names to ID
		--
		set @parentID = 0
		--
		SELECT @parentID = T_AuxInfo_Category.ID
		FROM T_AuxInfo_Target INNER JOIN
		   T_AuxInfo_Category ON 
		   T_AuxInfo_Target.ID = T_AuxInfo_Category.Target_Type_ID
		WHERE (T_AuxInfo_Target.Name = @targetName) AND 
		   (T_AuxInfo_Category.Name = @categoryName)
   		--
		if @parentID = 0
		begin
			set @msg = 'Could not resolve parent ID'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- is subcategory already in table?
		--
		set @tmpID = 0
		--
		SELECT @tmpID = ID
		FROM T_AuxInfo_Subcategory
		WHERE (Parent_ID = @parentID) AND (Name = @subcategoryName)
		--
		if @tmpID <> 0
		begin
			set @msg = 'Cannot add: subcategory already exists for this target'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- calculate new sequence
		--
		set @tmpSeq = 0
		--
		SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
		FROM T_AuxInfo_Subcategory
		WHERE (Parent_ID = @parentID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		-- future: check error?
		--
		set @tmpSeq = @tmpSeq + 1
		
		-- insert new subcategory for parent
		--
		INSERT INTO T_AuxInfo_Subcategory
		   (Name, Sequence, Parent_ID)
		VALUES (@subcategoryName, @tmpSeq, @parentID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert subcategory failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	end -- mode 'AddSubcategory'

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'AddItem'
	begin
		-- resolve parent names to ID
		--
		set @parentID = 0
		--
		SELECT @parentID = T_AuxInfo_Subcategory.ID
		FROM T_AuxInfo_Target INNER JOIN
		   T_AuxInfo_Category ON 
		   T_AuxInfo_Target.ID = T_AuxInfo_Category.Target_Type_ID INNER
		    JOIN
		   T_AuxInfo_Subcategory ON 
		   T_AuxInfo_Category.ID = T_AuxInfo_Subcategory.Parent_ID
		WHERE (T_AuxInfo_Target.Name = @targetName) AND 
		   (T_AuxInfo_Category.Name = @categoryName) AND 
		   (T_AuxInfo_Subcategory.Name = @subcategoryName)
   		--
		if @parentID = 0
		begin
			set @msg = 'Could not resolve parent ID'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- is item already in table?
		--
		set @tmpID = 0
		--
		SELECT @tmpID = ID
		FROM T_AuxInfo_Description
		WHERE (Parent_ID = @parentID) AND (Name = @itemName)
		--
		if @tmpID <> 0
		begin
			set @msg = 'Cannot add: item already exists for this target'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- calculate new sequence
		--
		set @tmpSeq = 0
		--
		SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
		FROM T_AuxInfo_Description
		WHERE (Parent_ID = @parentID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		-- future: check error?
		--
		set @tmpSeq = @tmpSeq + 1
		
		-- insert new item for parent
		--
		INSERT INTO T_AuxInfo_Description
		   (Name, Parent_ID, Sequence, DataSize, HelperAppend)
		VALUES (@itemName, @parentID, @tmpSeq, @Param1, @Param2)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert item failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	end -- mode 'AddItem'


	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'AddAllowedValue'
	begin
		-- resolve parent names to ID
		--
		set @parentID = 0
		--
  		SELECT @parentID = T_AuxInfo_Description.ID
		FROM T_AuxInfo_Target INNER JOIN
		   T_AuxInfo_Category ON 
		   T_AuxInfo_Target.ID = T_AuxInfo_Category.Target_Type_ID INNER
		    JOIN
		   T_AuxInfo_Subcategory ON 
		   T_AuxInfo_Category.ID = T_AuxInfo_Subcategory.Parent_ID INNER
		    JOIN
		   T_AuxInfo_Description ON 
		   T_AuxInfo_Subcategory.ID = T_AuxInfo_Description.Parent_ID
		WHERE (T_AuxInfo_Target.Name = @targetName) AND 
		   (T_AuxInfo_Category.Name = @categoryName) AND 
		   (T_AuxInfo_Subcategory.Name = @subcategoryName) AND 
		   (T_AuxInfo_Description.Name = @itemName)
   		--
		if @parentID = 0
		begin
			set @msg = 'Could not resolve parent ID'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- is item already in table?
		--
		set @tmpID = 0
		--
		SELECT @tmpID = AuxInfoID
		FROM T_AuxInfo_Allowed_Values
		WHERE (AuxInfoID = @parentID) AND (Value = @Param1)
		--
		if @tmpID <> 0
		begin
			set @msg = 'Cannot add: allowed value already exists for this target'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		
		-- insert new item for parent
		--
		INSERT INTO T_AuxInfo_Allowed_Values
		   (AuxInfoID, Value)
		VALUES (@parentID, @Param1)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert item failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	end -- mode 'AddAllowedValue'


	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'UpdateItem'
	begin
		-- find item ID
		--
		set @tmpID = 0
		--
		SELECT @tmpID = Item_ID
		FROM V_AuxInfo_Definition
		WHERE (Target = @targetName) AND 
		   (Category = @categoryName) AND 
		   (Subcategory = @subcategoryName) AND 
		   (Item = @itemName)
		--
		if @tmpID = 0
		begin
			set @msg = 'Cannot resolve item name to ID'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		
		-- get current values of stuff
		-- so that blank input values can default
		--
		declare @Sequence tinyInt 
		declare @DataSize int
		declare @HelperAppend char(1)
		--
		SELECT 
			@Sequence = Sequence, 
			@DataSize = DataSize, 
			@HelperAppend = HelperAppend
		FROM T_AuxInfo_Description
		WHERE (ID = @tmpID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'could not get current value of item'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
		--
		if @seq <> 0
		begin
			set @Sequence = @seq
		end
		--
		if @Param1 <> ''
		begin
			set @DataSize = @Param1 
		end
		--
		if @Param2 <> ''
		begin
			set @HelperAppend = @Param2
		end

		-- update item
		--
		UPDATE T_AuxInfo_Description
		SET 
			Sequence = @Sequence, 
			DataSize = @DataSize, 
			HelperAppend = @HelperAppend
		WHERE (ID = @tmpID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update item failed'
			RAISERROR (@msg, 10, 1)
			return 51000
		end
	end -- mode 'AddItem'



	---------------------------------------------------
	-- 
	---------------------------------------------------


	return 0
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfoDefinition] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfoDefinition] TO [Limited_Table_Write] AS [dbo]
GO
