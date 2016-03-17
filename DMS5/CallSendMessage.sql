/****** Object:  StoredProcedure [dbo].[CallSendMessage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CallSendMessage
/****************************************************
**
**  Desc:	Requests creation of data storage folder
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	04/29/2010
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
(
	@ID VARCHAR(256),
	@mode varchar(32),
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	DECLARE @result INT

	---------------------------------------------------
	-- Create a temporary table to hold any messages returned by the program
	---------------------------------------------------
	--
	CREATE TABLE #exec_std_out (
		line_number INT IDENTITY,
		line_contents NVARCHAR(4000) NULL
	)	

	-----------------------------------------------
	-- Use master..xp_cmdshell to call the message
	-- sending program and get its std_out into
	-- the temp table
	-----------------------------------------------
	--16 gigasax DMS5_T3 dms_file_storage_debug sample_submission

	DECLARE @appPath NVARCHAR(256)
	SET @appPath = 'C:\DMS_Programs\DBMessageSender3\'
	--
	DECLARE @appName NVARCHAR(64)
	SET @appName = 'DBMessageSender.exe'
	--
	DECLARE @broker NVARCHAR(64)
	SET @broker = 'dms_file_storage_production' --  dms_file_storage_debug
	--
	DECLARE @args NVARCHAR(256)
	SET @args = @ID + ' localhost ' +  DB_NAME() + ' ' + @broker + ' ' + @mode
	--
	Declare @cmd nvarchar(4000)
	Set @cmd = @appPath + @appName + ' ' + @args
	--
	insert into #exec_std_out
	EXEC @result = master..xp_cmdshell @cmd 
	--
	if @result <> 0
	Begin
		SELECT @message = @message + ' ' + ISNULL(line_contents, '') FROM #exec_std_out
		set @myError = @result
		goto Done
	End
		
	
Done:
--	PRINT 'Out:' + CONVERT(VARCHAR(12), @myError)
--	SELECT '->' + line_contents FROM #exec_std_out

	DROP TABLE #exec_std_out	
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[CallSendMessage] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CallSendMessage] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CallSendMessage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CallSendMessage] TO [PNL\D3M580] AS [dbo]
GO
