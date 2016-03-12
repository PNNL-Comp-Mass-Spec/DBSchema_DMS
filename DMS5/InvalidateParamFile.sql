/****** Object:  StoredProcedure [dbo].[InvalidateParamFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE InvalidateParamFile
/****************************************************
**
**	Desc: Marks existing parameter file as invalid
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@paramFileName  name of new param file description
**
**		Auth: jee
**		Date: 08/17/2004
**    
*****************************************************/
(
	@paramFileName varchar(255)
)
As
	set nocount on

	declare @msg varchar(255)
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
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
	
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @ParamFileID int
	set @ParamFileID = 0
	--
	execute @ParamFileID = GetParamFileID @ParamFileName
	
	-- cannot update a non-existent entry
	--
	if @ParamFileID = 0
	begin
		set @msg = 'Cannot update: Param File "' + @ParamFileName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	set @myError = 0
	--
	UPDATE T_Param_Files 
	SET 
		Valid = 1, Date_Modified = GETDATE()
		
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

	return 0

GO
GRANT EXECUTE ON [dbo].[InvalidateParamFile] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[InvalidateParamFile] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[InvalidateParamFile] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[InvalidateParamFile] TO [PNL\D3M578] AS [dbo]
GO
