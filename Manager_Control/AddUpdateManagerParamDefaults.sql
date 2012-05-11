/****** Object:  StoredProcedure [dbo].[AddUpdateManagerParamDefaults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateManagerParamDefaults
/****************************************************
**
**	Desc: 
**	Adds new or updates existing manager control default param values in database
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	jds
**	Date:	09/07/2007
**			04/16/2009 mem - Updated comparison of @tVal and @vFld to use IsNull
**    
*****************************************************/
(
	@targetEntityName varchar(128) = '',
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
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future

	---------------------------------------------------
	-- Resolve managerID from @targetEntityName
	---------------------------------------------------

	declare @mgrTypeID int

	SELECT @mgrTypeID = MT_TypeID
	FROM T_MgrTypes
	WHERE (MT_TypeName = @targetEntityName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @msg = 'Could not look up manager ID for target Entity Name: "' + @targetEntityName + '"'
		RAISERROR (@msg, 10, 1)
		return 51000
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
		--print '========== row:' +  + convert(varchar, @count)

		-- get the next field from the item name list
		--
		execute @done = NextField @itemNameList, @delim, @inPos output, @inFld output
		
		-- process the next field from the item value list
		--
		execute NextField @itemValueList, @delim, @vPos output, @vFld output

		-- resolve item name to item ID
		--
		set @itemID = 0
		SELECT @itemID = paramID
		FROM T_ParamType
		WHERE ParamName = @inFld
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @itemID = 0
		begin
			set @msg = 'Could not resolve item to ID: "' + @inFld + '"'
			RAISERROR (@msg, 10, 1)
			return 51001
		end


		-- does entry exist in value table?
		--
		SELECT @tVal = isnull(DefaultValue, '')
		FROM T_MgrType_ParamType_Map
		WHERE (ParamTypeID = @itemID) AND (MgrTypeID = @mgrTypeID)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error in searching for existing value for item: "' + @inFld + '"'
			RAISERROR (@msg, 10, 1)
			return 51001
		end

		-- if entry exists in value table, update it
		-- otherwise insert it
		--
		if @myRowCount > 0 
			begin
				if IsNull(@tVal, '') <> @vFld
				begin
					UPDATE T_MgrType_ParamType_Map
					SET DefaultValue = @vFld
					WHERE (ParamTypeID = @itemID) AND (MgrTypeID = @mgrTypeID)
				end
			end
		else
			begin
				INSERT INTO T_MgrType_ParamType_Map
				(ParamTypeID, MgrTypeID, DefaultValue)
				VALUES (@itemID, @mgrTypeID, @vFld)
			end

		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Value was not updated for item: "' + @inFld + '"'
			RAISERROR (@msg, 10, 1)
			return 51001
		end
		
nextItem:
	end


	---------------------------------------------------
	-- 
	---------------------------------------------------


	return 0
GO
GRANT EXECUTE ON [dbo].[AddUpdateManagerParamDefaults] TO [DMSWebUser] AS [dbo]
GO
