/****** Object:  StoredProcedure [dbo].[CallSendMessage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CallSendMessage
/****************************************************
**
**  Desc:	Requests creation of data storage folder for data package
**			Only calls the external program if @mode is 'add'
**			If @mode is 'update', then does nothing
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	11/05/2009 grk - Initial version
**			11/02/2015 mem - Now calling PostLogEntry
**			               - Changed @ID from varchar(128) to int
**			03/17/2016 mem - Add comment about deprecating the use of this procedure because we don't want to grant Execute permission on [sys].[xp_cmdshell] to [DMSWebUser]
**
*****************************************************/
(
	@ID int,
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

	Declare @IDText varchar(12) = Cast(@ID as varchar(12))
	Declare @result int
	Declare @logMessage varchar(512)

	---------------------------------------------------
	-- Create a temporary table to hold any messages returned by the program
	---------------------------------------------------
	--
	CREATE TABLE #exec_std_out (
		line_number INT IDENTITY,
		line_contents NVARCHAR(4000) NULL
	)	

	If @mode = 'add' -- or @mode = 'update'
	Begin
		-----------------------------------------------
		-- Use master..xp_cmdshell to call the message
		-- sending program and get its std_out into
		-- the temp table
		-----------------------------------------------

		DECLARE @appPath NVARCHAR(256)
		SET @appPath = 'C:\DMS_Programs\DBMessageSender\'
		
		DECLARE @appName NVARCHAR(64)
		SET @appName = 'DBMessageSender.exe'
		
		DECLARE @args NVARCHAR(256)
		SET @args = @IDText + ' localhost ' +  DB_NAME() + ' ' + @mode
		
		Declare @cmd nvarchar(4000)
		Set @cmd = @appPath + @appName + ' ' + @args
		
		-- Note: for this to work with the DMSWebUser user we need to use:
		-- GRANT EXECUTE ON [sys].[xp_cmdshell] TO [DMSWebUser]
		-- However, when migrating to a new server in February 2016 it was decided not to grant this permission
		-- and to instead stop using this stored procedure
		--
		insert into #exec_std_out
		EXEC @result = master..xp_cmdshell @cmd 
		
		if @result = 0
		Begin
			Declare @folderName varchar(128)
			
			SELECT @folderName = Package_File_Folder
			FROM T_Data_Package
			WHERE ID = @ID

			Set @logMessage = 'Created data package folder: ' + @folderName		
			exec PostLogEntry 'Normal', @logMessage, 'CallSendMessage'
		End
		Else
		Begin
			SELECT @message = @message + ' ' + ISNULL(line_contents, '') FROM #exec_std_out
			
			Set @logMessage = 'Error creating folder for data package ' + @IDText + ': ' + @message			
			exec PostLogEntry 'Error', @logMessage, 'CallSendMessage'
			
			Set @logMessage = 'Command used: ' + @cmd
			exec PostLogEntry 'Debug', @logMessage, 'CallSendMessage'
			 
			set @myError = @result
			goto Done
		End
		
	End
	
Done:
--	PRINT 'Out:' + CONVERT(VARCHAR(12), @myError)
--	SELECT '->' + line_contents FROM #exec_std_out

	DROP TABLE #exec_std_out	
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CallSendMessage] TO [DDL_Viewer] AS [dbo]
GO
