/****** Object:  StoredProcedure [dbo].[AddUpdateAuxInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateAuxInfo
/****************************************************
**
**	Desc: 
**	Adds new or updates existing auxiliary information in database
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		3/27/2002 -- initial release
**      12/18/2007 grk - Improved ability to handle target ID if supplied as target name
**      06/30/2008 jds - Added error message to "Resolve target name and entity name to entity ID" section
**      05/15/2009 jds - Added a return if just performing a check_add or check_update
**		08/21/2010 grk - try-catch for error handling
**    
*****************************************************/
(
	@targetName varchar(128) = '',
	@targetEntityName varchar(128) = '',
	@categoryName varchar(128) = '', 
	@subCategoryName varchar(128) = '', 
	@itemNameList varchar(4000) = '',
	@itemValueList varchar(3000) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	BEGIN TRY 

	---------------------------------------------------
	-- what mode are we in
	---------------------------------------------------
	
	if (@mode = 'check_update' or @mode = 'check_add')
	begin
		SET @mode = 'check_only'
	end

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future

	---------------------------------------------------
	-- has ID been supplied as target name?
	---------------------------------------------------

	declare @targetID int
	set @targetID = 0

	if ISNUMERIC(@targetEntityName) > 0
	begin
		set @targetID = cast(@targetEntityName as int)
	end
	else
	begin --<1>
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
			RAISERROR (@msg, 11, 1)
		end

		IF @mode <> 'check_only'
		BEGIN --<a>
			---------------------------------------------------
			-- Resolve target name and entity name to entity ID
			---------------------------------------------------
			
			declare @sql nvarchar(1024)
			
			set @sql = N'' 
			set @sql = @sql + 'SELECT @targetID = ' + @tgtTableIDCol
			set @sql = @sql + ' FROM ' + @tgtTableName
			set @sql = @sql + ' WHERE ' + @tgtTableNameCol
			set @sql = @sql + ' = ''' + @targetEntityName + ''''
			
			exec sp_executesql @sql, N'@targetID int output', @targetID = @targetID output
			--
			if @targetID = 0
			begin
				set @msg = 'Could not resolve target name and entity name to entity ID: "' + @targetEntityName + '" '
				RAISERROR (@msg, 11, 2)
			end
		END --<a>
	end --<1>

	---------------------------------------------------
	-- Adding code to return if just a verification check
	-- if we got this far, everything must be ok
	---------------------------------------------------
	if (@mode = 'check_update' or @mode = 'check_add')
	begin
		return 0
	end


	-- if list is empty, we are done
	--
	if LEN(@itemNameList) = 0
		return 0

	declare @delim char(1)
	set @delim = '!'

	declare @done int
	declare @count int

	--
	declare @inPos int
	set @inPos = 1
	declare @inFld varchar(128)
	--
	declare @vPos int
	set @vPos = 1
	declare @vFld varchar(128)

	declare @itemID int
	declare @tVal varchar(128)
	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	-- process lists into rows
	-- and insert into DB table
	--
	set @count = 0
	set @done = 0

	while @done = 0
	begin
		set @count = @count + 1

		-- get the next field from the item name list
		--
		execute @done = NextField @itemNameList, @delim, @inPos output, @inFld output
		
		-- process the next field from the item value list
		--
		execute NextField @itemValueList, @delim, @vPos output, @vFld output

		-- resolve item name to item ID
		--
		set @itemID = 0
		SELECT @itemID = Item_ID
		FROM V_AuxInfo_Definition
		WHERE 
			(Target = @targetName) AND 
			(Category = @categoryName) AND 
			(Subcategory = @subCategoryName) AND 
			(Item = @inFld)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @itemID = 0
		begin
			set @msg = 'Could not resolve item to ID: "' + @inFld + '"'
			RAISERROR (@msg, 11, 1)
		end

		IF @mode <> 'check_only'
		BEGIN --<b>
			-- if value is blank, delete any existing entry from value table
			--
			if @vFld = ''
			begin
				DELETE FROM T_AuxInfo_Value 
				WHERE (AuxInfo_ID = @itemID) AND (Target_ID = @targetID)
				goto nextItem
			end

			-- does entry exist in value table?
			--
			SELECT @tVal = Value
			FROM T_AuxInfo_Value
			WHERE (AuxInfo_ID = @itemID) AND (Target_ID = @targetID)		
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error in searching for existing value for item: "' + @inFld + '"'
				RAISERROR (@msg, 11, 1)
			end

			-- if entry exists in value table, update it
			-- otherwise insert it
			--
			if @myRowCount > 0 
				begin
					if @tVal <> @vFld
					begin
						UPDATE T_AuxInfo_Value
						SET Value = @vFld
						WHERE (AuxInfo_ID = @itemID) AND (Target_ID = @targetID)
					end
				end
			else
				begin
					INSERT INTO T_AuxInfo_Value
					(Target_ID, AuxInfo_ID, Value)
					VALUES (@targetID, @itemID, @vFld)
				end
		END --<b>
		
nextItem:
	end

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateAuxInfo] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAuxInfo] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfo] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfo] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfo] TO [PNL\D3M580] AS [dbo]
GO
