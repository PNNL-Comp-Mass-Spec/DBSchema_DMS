/****** Object:  StoredProcedure [dbo].[DeleteParamFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteParamFile
/****************************************************
**
**	Desc: Deletes given Sequest Param file from the T_Param_Files
**        and all referencing tables
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	kja
**	Date:	07/22/2004 mem
**			02/12/2010 mem - Now updating @message when the parameter file is successfully deleted
**    
*****************************************************/
(
	@ParamFileName varchar(255),
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

	declare @ParamFileID int
--	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- get ParamFileID
	---------------------------------------------------

	SELECT  
		@ParamFileID = Param_File_ID
	FROM T_Param_Files 
	WHERE (Param_File_Name = @ParamFileName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not get ID for Param File "' + @ParamFileName + '"'
		print @msg
		RAISERROR (@msg, 10, 1)
		return 51140
	end
	
	If @myRowCount = 0
	Begin
		set @msg = 'Param file not found in T_Param_Files: ' + @ParamFileName
		print @msg
		RAISERROR (@msg, 10, 1)
		return 51141
	End

	execute @result = DeleteParamFileByID @ParamFileID, @msg output
	
	If @result = 0
	Begin
		Set @message = 'Deleted parameter file ' + @ParamFileName
		Print @message
	End
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFile] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteParamFile] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFile] TO [Limited_Table_Write] AS [dbo]
GO
