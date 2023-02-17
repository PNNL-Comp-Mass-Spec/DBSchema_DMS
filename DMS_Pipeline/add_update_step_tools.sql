/****** Object:  StoredProcedure [dbo].[AddUpdateStepTools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateStepTools
/****************************************************
**
**  Desc: Adds new or edits existing T_Step_Tools
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	09/24/2008
**			12/17/2009 mem - Added parameter @ParamFileStoragePath
**			10/17/2011 mem - Added parameter @MemoryUsageMB
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@Name varchar(64),
	@Type varchar(128),
	@Description varchar(512),
	@SharedResultVersion smallint,
	@FilterVersion smallint,
	@CPULoad smallint,
	@MemoryUsageMB int,
	@ParameterTemplate text,
	@ParamFileStoragePath varchar(256),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateStepTools', @raiseError = 1;
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM  T_Step_Tools
	WHERE Name = @Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error searching for existing entry'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	-- cannot update a non-existent entry
	--
	if @mode = 'update' and @tmp = 0
	begin
		set @message = 'Could not find "' + @Name + '" in database'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	-- cannot add an existing entry
	--
	if @mode = 'add' and @tmp <> 0
	begin
		set @message = '"' + @Name + '" already exists in database'
		RAISERROR (@message, 10, 1)
		return 51009
	end


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
	
		INSERT INTO T_Step_Tools (
		Name, 
			Type, 
			Description, 
			Shared_Result_Version, 
			Filter_Version, 
			CPU_Load, 
			Memory_Usage_MB,
			Parameter_Template,
			Param_File_Storage_Path
		) VALUES (
			@Name, 
			@Type, 
			@Description, 
			@SharedResultVersion, 
			@FilterVersion, 
			@CPULoad, 
			@MemoryUsageMB,
			@ParameterTemplate,
			@ParamFileStoragePath
		)
		/**/
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		  set @message = 'Insert operation failed'
		  RAISERROR (@message, 10, 1)
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
	
		UPDATE T_Step_Tools 
		SET 
		  Type = @Type, 
		  Description = @Description, 
		  Shared_Result_Version = @SharedResultVersion, 
		  Filter_Version = @FilterVersion, 
		  CPU_Load = @CPULoad, 
		  Memory_Usage_MB = @MemoryUsageMB,
		  Parameter_Template = @ParameterTemplate,
		  Param_File_Storage_Path = @ParamFileStoragePath
		WHERE (Name = @Name)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		  set @message = 'Update operation failed: "' + @Name + '"'
		  RAISERROR (@message, 10, 1)
		  return 51004
		end
	end -- update mode

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStepTools] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateStepTools] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateStepTools] TO [Limited_Table_Write] AS [dbo]
GO
