/****** Object:  StoredProcedure [dbo].[VerifyFileExists] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure VerifyFileExists
/****************************************************
**
**	Desc: 
**		Verifies that given file exisits
**
**	Parameters:
**
**		Auth: grk
**		Date: 06/07/2004
**    
*****************************************************/
	@filePath varchar(255),
	@message varchar(255) out
AS
	set nocount on
	declare @myError int
	set @myError = 0
	
	set @message = ''
	
	declare @result int
	
	DECLARE @FSOObject int
	DECLARE @TxSObject int
	DECLARE @hr int
	
	-----------------------------------------------
	-- Deal with existing files
	-----------------------------------------------
	-- Create a FileSystemObject object.
	--
	EXEC @hr = sp_OACreate 'Scripting.FileSystemObject', @FSOObject OUT
	IF @hr <> 0
	BEGIN
	    EXEC LoadGetOAErrorMessage @FSOObject, @hr, @message OUT
		set @myError = 60
		goto Done
	END
	-- verify that file exists
	--
	EXEC @hr = sp_OAMethod  @FSOObject, 'FileExists', @result OUT, @filePath
	IF @hr <> 0
	BEGIN
	    EXEC LoadGetOAErrorMessage @FSOObject, @hr, @message OUT
		set @myError = 60
	    goto DestroyFSO
	END
	--
	If @result = 0
	begin
		set @message = 'file does not exist'
		set @myError = 60
	    goto DestroyFSO
	end


	-----------------------------------------------
	-- clean up file system object
	-----------------------------------------------
  
DestroyFSO:
	-- Destroy the FileSystemObject object.
	--
	EXEC @hr = sp_OADestroy @FSOObject
	IF @hr <> 0
	BEGIN
	    EXEC LoadGetOAErrorMessage @FSOObject, @hr, @message OUT
		set @myError = 60
		goto done
	END

	-----------------------------------------------
	-- Exit
	-----------------------------------------------
Done:
	
	return @myError

GO
GRANT EXECUTE ON [dbo].[VerifyFileExists] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[VerifyFileExists] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[VerifyFileExists] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[VerifyFileExists] TO [PNL\D3M580] AS [dbo]
GO
