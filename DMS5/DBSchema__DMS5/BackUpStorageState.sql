/****** Object:  StoredProcedure [dbo].[BackUpStorageState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure BackUpStorageState
/****************************************************
**
**	Desc: 
**		Copies current contents of storage and 
**		instrument tables into their backup tables
**
**	Return values: 0: failure, otherwise, experiment ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 4/18/2002
**		04/07/2006 -- Got ride of CDBurn stuff
**    
*****************************************************/
(
	@message varchar(255) output
)
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- 
	---------------------------------------------------

	DELETE FROM t_storage_path_bkup
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Clear storage backup table failed'
		return 1
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	INSERT INTO t_storage_path_bkup
	   (SP_path_ID, SP_path, SP_vol_name_client, 
	   SP_vol_name_server, SP_function, SP_instrument_name, 
	   SP_code, SP_descripton)
	SELECT SP_path_ID, SP_path, SP_vol_name_client, 
	   SP_vol_name_server, SP_function, SP_instrument_name, 
	   SP_code, SP_descripton
	FROM t_storage_path
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	--
	if @myError <> 0
	begin
		set @message = 'Copy storage backup failed'
		return 1
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	DELETE FROM T_Instrument_Name_Bkup
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	--
	if @myError <> 0
	begin
		set @message = 'Clear instrument backup table failed'
		return 1
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	INSERT INTO [T_Instrument_Name_Bkup]
	   (IN_name, Instrument_ID, IN_class, IN_source_path_ID, 
	   IN_storage_path_ID, IN_capture_method, 
	   IN_Room_Number, 
	   IN_Description)
	SELECT 
	IN_name, 
	Instrument_ID, 
	IN_class, 
	IN_source_path_ID, 
	   IN_storage_path_ID, 
	   IN_capture_method, 
	   IN_Room_Number, 
	   IN_Description
	FROM T_Instrument_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	--
	if @myError <> 0
	begin
		set @message = 'Copy instrument backup failed'
		return 1
	end

	return @myError


GO
