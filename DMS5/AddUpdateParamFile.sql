/****** Object:  StoredProcedure [dbo].[AddUpdateParamFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateParamFile
/****************************************************
**
**	Desc: Adds new or updates existing parameter file in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@paramFileName  name of new param file description
**		@paramFileDesc  description of paramfileentry 
**	
**
**		Auth: kja
**		Date: 07/22/2004
**    
*****************************************************/
(
	@paramFileName varchar(255), 
	@paramFileDesc varchar(1024),
	@paramFileTypeID int, 
	@mode varchar(12) = 'add', -- or 'update' : autochanges to 'update' if paramFileID exists
	@message varchar(512) output
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

	set @myError = 0
	if LEN(@paramFileName) < 1
	begin
		set @myError = 51000
		RAISERROR ('ParamFileName was blank',
			10, 1)
	end

	--

	if LEN(@paramFileDesc) < 1 and @paramFileTypeID = 1000
	begin
		set @myError = 51001
		RAISERROR ('ParamFileDesc was blank',
			10, 1)
	end

	--
	
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @ParamFileID int
	set @ParamFileID = 0
	--
	execute @ParamFileID = GetParamFileID @ParamFileName
	
	if @ParamFileID <> 0
	begin
		set @mode = 'update'
	end

	-- cannot create an entry that already exists
	--
	if @ParamFileID <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Param File "' + @ParamFileName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @ParamFileID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Param File "' + @ParamFileName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Param_Files (
			Param_File_Name, 
			Param_File_Description, 
			Param_File_Type_ID, 
			Date_Created, 
			Date_Modified, 
			Valid
		) VALUES (
			@ParamFileName, 
			@ParamFileDesc, 
			@ParamFileTypeID, 
			GETDATE(),  
			GETDATE(),
			1
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @ParamFileName + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- add mode


	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Param_Files 
		SET 
			Param_File_Description = @ParamFileDesc, Date_Modified = GETDATE()
			
		WHERE (Param_File_Name = @ParamFileName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @ParamFileName + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateParamFile] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateParamFile] TO [PNL\D3M578] AS [dbo]
GO
