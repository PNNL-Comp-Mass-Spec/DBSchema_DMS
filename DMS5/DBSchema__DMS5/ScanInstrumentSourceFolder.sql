/****** Object:  StoredProcedure [dbo].[ScanInstrumentSourceFolder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure ScanInstrumentSourceFolder
/****************************************************
**		File: 
**		Desc: 
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**		Auth: grk
**		Date: 4/25/2002
**
**		NOTE: DO NOT USE IN 'Update' MODE
**		This is under development pending resolution
**		of access permissions issue inside xp_cmdshell
**    
*****************************************************/
	@instrumentName varchar(64),
	@scanFileDir varchar(256) output,
	@mode varchar(12) = 'update', -- or ''
	@message varchar(512) output
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
--	set @message = ''

	declare @msg varchar(256)

	---------------------------------------------------
	-- look up paths for scanner program
	---------------------------------------------------
	declare @scanProgPath varchar(255)
	
	set @scanProgPath = ''
	--
	SELECT @scanProgPath = Server
	FROM T_MiscPaths
	WHERE ([Function] = 'InstrumentSourceScanProg')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @scanProgPath = ''
	begin
		set @msg = 'Could not get scan program path'
		RAISERROR (@msg, 10, 1)
		return 51007
	end
	
	set @scanFileDir = ''
	--
	SELECT @scanFileDir = Server
	FROM T_MiscPaths
	WHERE ([Function] = 'InstrumentSourceScanDir')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @scanProgPath = ''
	begin
		set @msg = 'could not get scan prog output dir'
		RAISERROR (@msg, 10, 1)
		return 51007
	end
	
	---------------------------------------------------
	-- execute scanner (if mode is 'update')
	---------------------------------------------------
	
	if @mode = 'update'
	begin
		declare @cmd varchar(256)
		declare @result int
	
		set @cmd =  @scanProgPath + ' ' + @instrumentName + ', '  + @scanFileDir
	
		exec @myError = master..xp_cmdshell @cmd
	end

	return @myError

GO
GRANT EXECUTE ON [dbo].[ScanInstrumentSourceFolder] TO [DMS_SP_User]
GO
