/****** Object:  StoredProcedure [dbo].[AddUpdateStorage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[AddUpdateStorage]
/****************************************************
**
**	Desc: 
**	Adds new or updates existing storage path
**	(saves current state of storage and instrument
**	 tables in backup tables)
**
**	Mode	Function:		Action
**			(cur.)	(new)	
**	----	------	-----	--------------------
**	
**	Add		(any)	raw		change any existing raw
**							for instrument to old,
**							set assigned storage of
**							instrument to new path
**	
**	Update	old		raw		change any existing raw
**							for instrument to old,
**							set assigned storage of
**							instrument to new path
**	
**	Update	raw		old		not allowed
**	
**	Add		(any)	inbox	not allowed if there is
**								an existing inbox path
**								for instrument
**	
**	Update	inbox	(any)	not allowed
**		
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	04/15/2002
**			05/01/2009 mem - Updated description field in t_storage_path to be named SP_description
**    
*****************************************************/
(
	@path varchar(255), 
	@volNameClient varchar(128),
	@volNameServer varchar(128),
	@storFunction varchar(50),
	@instrumentName varchar(50),
	@description varchar(255) = '(na)',
    @ID varchar(32) output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @result int
	
	declare @msg varchar(256)
	
	declare @machineName varchar(64)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@path) < 1
	begin
		set @msg = 'path was blank'
		RAISERROR (@msg, 10, 1)
		return 51036
	end

	if LEN(@instrumentName) < 1
	begin
		set @msg = 'instrumentName was blank'
		RAISERROR (@msg, 10, 1)
		return 51036
	end

	if @storFunction not in ('inbox', 'old-storage', 'raw-storage')
	begin
		set @msg = 'Function "' + @storFunction + '" is not recognized'
		RAISERROR (@msg, 10, 1)
		return 51036
	end

	if @mode not in ('add', 'update')
	begin
		set @msg = 'Function "' + @mode + '" is not recognized'
		RAISERROR (@msg, 10, 1)
		return 51036
	end
	
	---------------------------------------------------
	-- Resolve machine name
	---------------------------------------------------
	
	if @storFunction = 'inbox'
		set @machineName = replace(@volNameServer, '\', '')
	else
		set @machineName = replace(@volNameClient, '\', '')
	
	---------------------------------------------------
	-- Only one input path allowed for given instrument
	---------------------------------------------------

	declare @num int
	set @num = 0

	SELECT @num = count(SP_path_ID)
	FROM t_storage_path
	WHERE 
		(SP_instrument_name = @instrumentName) AND 
		(SP_function = @storFunction)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not check existing storage record'
		RAISERROR (@msg, 10, 1)
		return 51012
	end

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	declare @tmpID int
	set @tmpID = 0
	--
	declare @oldFunction varchar(50)
	set @oldFunction = ''
	--
	declare @spID int
	set @spID = cast(@ID as int)

	-- cannot update a non-existent entry
	--
	if @mode = 'update'
	begin
		SELECT 
			@tmpID = SP_path_ID,
			@oldFunction = SP_function
		FROM t_storage_path
		WHERE (SP_path_ID = @spID)
		--
		if @tmpID = 0
		begin	
			set @msg = 'Cannot update:  Storage path "' + @ID + '" is not in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @Mode = 'add'
	begin


		---------------------------------------------------
		-- begin transaction
		---------------------------------------------------
		--
		declare @transName varchar(32)
		set @transName = 'AddUpdateStoragePath'
		begin transaction @transName

		---------------------------------------------------
		-- save existing state of instrument and storage tables
		---------------------------------------------------
		--
		exec @result = BackUpStorageState @msg output
		--
		if @result <> 0
		begin
			rollback transaction @transName
			set @msg = 'Backup failed: ' + @msg
			RAISERROR (@msg, 10, 1)
			return 51028
		end

		---------------------------------------------------
		-- clean up any existing raw-storage assignments 
		-- for instrument
		---------------------------------------------------
		--
		if @storFunction = 'raw-storage'
		begin

			-- build list of paths that will be changed
			--
			set @message = ''
			--
			SELECT @message = @message + cast(SP_path_ID as varchar(12)) + ', '
			FROM t_storage_path
			WHERE (SP_function = 'raw-storage') AND 
			   (SP_instrument_name = @instrumentName)			

			-- set any existing raw-storage paths for instrument 
			-- already in storage table to old-storage
			--
			UPDATE t_storage_path
			SET SP_function = 'old-storage'
			WHERE 
				(SP_function = 'raw-storage') AND 
				(SP_instrument_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				set @msg = 'Changing existing raw-storage failed'
				RAISERROR (@msg, 10, 1)
				return 51042
			end

			set @message = cast(@myRowCount as varchar(12)) + ' path(s) (' + @message + ') were changed from raw-storage to old-storage' 
		end

		---------------------------------------------------
		-- validate against any existing inbox assignments
		---------------------------------------------------

		if @storFunction = 'inbox'
		begin
			set @tmpID = 0
			--
			SELECT @tmpID = SP_path_ID
			FROM t_storage_path
			WHERE 
				(SP_function = 'inbox') AND 
				(SP_instrument_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			-- future: error check
			--
			if @tmpID <> 0
			begin
				rollback transaction @transName
				set @msg = 'Cannot add new inbox path if one (' + cast(@tmpID as varchar(12))+ ') already exists for instrument'
				RAISERROR (@msg, 10, 1)
				return 51036
			end
		end

		---------------------------------------------------
		-- 
		---------------------------------------------------
		declare @newID int
		--
		INSERT INTO t_storage_path (
			SP_path, 
			SP_vol_name_client, 
			SP_vol_name_server, 
			SP_function, 
			SP_instrument_name, 
			SP_description,
			SP_machine_name
		) VALUES (
			@path,
			@volNameClient,
			@volNameServer,
			@storFunction,
			@instrumentName,
			@description,
			@machineName
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount, @newID = @@identity
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert new operation failed'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		
		---------------------------------------------------
		-- update the assigned storage for the instrument
		---------------------------------------------------
		--
		if @storFunction = 'raw-storage'
		begin
			UPDATE T_Instrument_Name
			SET IN_storage_path_ID = @newID
			WHERE (IN_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				set @msg = 'Update of instrument assigned storage failed'
				RAISERROR (@msg, 10, 1)
				return 51043
			end
		end

		if @storFunction = 'inbox'
		begin
			UPDATE T_Instrument_Name
			SET IN_source_path_ID = @newID
			WHERE (IN_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				set @msg = 'Update of instrument assigned source failed'
				RAISERROR (@msg, 10, 1)
				return 51043
			end
		end

		-- return job number of newly created job
		--
		set @ID = cast(@newID as varchar(32))

		commit transaction @transName

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		-- begin transaction
		---------------------------------------------------
		--
		set @transName = 'AddUpdateStoragePath'
		begin transaction @transName

		---------------------------------------------------
		-- save existing state of instrument and storage tables
		---------------------------------------------------
		--
		exec @result = BackUpStorageState @msg output
		--
		if @result <> 0
		begin
			rollback transaction @transName
			set @msg = 'Backup failed: ' + @msg
			RAISERROR (@msg, 10, 1)
			return 51028
		end

		---------------------------------------------------
		-- clean up any existing raw-storage assignments 
		-- for instrument when changing to new raw-storage path
		---------------------------------------------------
		--
		if @storFunction = 'raw-storage' and @oldFunction <> 'raw-storage'
		begin

			-- build list of paths that will be changed
			--
			set @message = ''
			--
			SELECT @message = @message + cast(SP_path_ID as varchar(12)) + ', '
			FROM t_storage_path
			WHERE (SP_function = 'raw-storage') AND 
			   (SP_instrument_name = @instrumentName)			

			-- set any existing raw-storage paths for instrument 
			-- already in storage table to old-storage
			--
			UPDATE t_storage_path
			SET SP_function = 'old-storage'
			WHERE 
				(SP_function = 'raw-storage') AND 
				(SP_instrument_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				set @msg = 'Changing existing raw-storage failed'
				RAISERROR (@msg, 10, 1)
				return 51042
			end

			---------------------------------------------------
			-- update the assigned storage for the instrument
			---------------------------------------------------
			--
			UPDATE T_Instrument_Name
			SET IN_storage_path_ID = @tmpID
			WHERE (IN_name = @instrumentName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				set @msg = 'Update of instrument assigned storage failed'
				RAISERROR (@msg, 10, 1)
				return 51043
			end

			set @message = cast(@myRowCount as varchar(12)) + ' path(s) (' + @message + ') were changed from raw-storage to old-storage' 
		end

		---------------------------------------------------
		-- validate against changing current raw-storage path
		-- to old-storage
		---------------------------------------------------
		--
		if @storFunction <> 'raw-storage' and @oldFunction = 'raw-storage'
		begin
			rollback transaction @transName
			set @msg = 'Cannot change existing raw-storage path to old-storage'
			RAISERROR (@msg, 10, 1)
			return 51037
		end

		---------------------------------------------------
		-- validate against any existing inbox assignments
		---------------------------------------------------

		if @storFunction <> 'inbox' and @oldFunction = 'inbox'
		begin
			rollback transaction @transName
			set @msg = 'Cannot change existing inbox path to another function'
			RAISERROR (@msg, 10, 1)
			return 51037
		end

		---------------------------------------------------
		-- 
		---------------------------------------------------
		--
		UPDATE t_storage_path
		SET 
			SP_path =@path, 
			SP_vol_name_client =@volNameClient, 
			SP_vol_name_server =@volNameServer, 
			SP_function =@storFunction, 
			SP_instrument_name =@instrumentName, 
			SP_description =@description,
			SP_machine_name = @machineName
		WHERE (SP_path_ID = @spID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		
		commit transaction @transName

	end -- update mode

	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateStorage] TO [DMS_Storage_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateStorage] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStorage] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStorage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStorage] TO [PNL\D3M580] AS [dbo]
GO
