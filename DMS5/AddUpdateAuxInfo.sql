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
**	Auth: grk
**			03/27/2002 -- initial release
**			12/18/2007 grk - Improved ability to handle target ID if supplied as target name
**			06/30/2008 jds - Added error message to "Resolve target name and entity name to entity ID" section
**			05/15/2009 jds - Added a return if just performing a check_add or check_update
**			08/21/2010 grk - try-catch for error handling
**			02/20/2012 mem - Now using temporary tables to parse @itemNameList and @itemValueList
**			02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**    
*****************************************************/
(
	@targetName varchar(128) = '',
	@targetEntityName varchar(128) = '',
	@categoryName varchar(128) = '', 
	@subCategoryName varchar(128) = '', 
	@itemNameList varchar(4000) = '',				-- AuxInfo names to update; delimiter is !
	@itemValueList varchar(3000) = '',				-- AuxInfo values; delimiter is !
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) = '' output
)
As
	Set XACT_ABORT, nocount on

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

	Set @itemNameList = IsNull(@itemNameList, '')
	Set @itemValueList = IsNull(@itemValueList, '')
	
	---------------------------------------------------
	-- has ID been supplied as target name?
	---------------------------------------------------

	declare @targetID int
	set @targetID = 0

	set @targetID = Try_Convert(Int, @targetEntityName)
	If @targetID IS NULL
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


	
	---------------------------------------------------
	-- Populate temorary tables using @itemNameList and @itemValueList
	---------------------------------------------------
	
	Declare @tblAuxInfoNames Table
	(
		EntryID int,
		ItemName varchar(256)
	)

	Declare @tblAuxInfoValues Table
	(
		EntryID int,
		ItemValue varchar(256)
	)
	
	INSERT INTO @tblAuxInfoNames (EntryID, ItemName)
	SELECT EntryID, Value
	FROM dbo.udfParseDelimitedListOrdered(@itemNameList, '!')
	ORDER BY EntryID
	

	INSERT INTO @tblAuxInfoValues (EntryID, ItemValue)
	SELECT EntryID, Value
	FROM dbo.udfParseDelimitedListOrdered(@itemValueList, '!')
	ORDER BY EntryID


	declare @done int = 0
	declare @count int = 0
	declare @EntryID int = -1
		
	declare @itemID int
	
	declare @inFld varchar(128)
	declare @vFld varchar(128)
	declare @tVal varchar(128)
	
	---------------------------------------------------
	-- Process @tblAuxInfoNames
	---------------------------------------------------

	while @done = 0
	begin -- <a>
	
		SELECT TOP 1 @EntryID = EntryID,
		             @inFld = ItemName
		FROM @tblAuxInfoNames
		WHERE EntryID > @EntryID
		ORDER BY EntryID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
			Set @Done = 1
		
		If @myRowCount = 1 And Len(IsNull(@inFld, '')) > 0 
		Begin -- <b>
			
			set @count = @count + 1
			
			-- Lookup the value for this aux info entry
			--		
			Set @vFld = ''
			--
			SELECT @vFld = ItemValue
			FROM @tblAuxInfoValues
			WHERE EntryID = @EntryID

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
			BEGIN --<c>
				-- if value is blank, delete any existing entry from value table
				--
				if @vFld = ''
				Begin
					DELETE FROM T_AuxInfo_Value 
					WHERE (AuxInfo_ID = @itemID) AND (Target_ID = @targetID)					
				End
				Else
				Begin -- <d>
				
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
					
				End -- </d>
				
			END -- </c>
		
		End -- </b>
	End -- </a>

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
