/****** Object:  StoredProcedure [dbo].[DeleteParamFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE DeleteParamFile
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
**		Auth: kja
**		Date: 7/22/2004
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
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	execute @result = DeleteParamFileByID @ParamFileID, @msg output
		
	return 0

GO
GRANT EXECUTE ON [dbo].[DeleteParamFile] TO [DMS_ParamFile_Admin]
GO
