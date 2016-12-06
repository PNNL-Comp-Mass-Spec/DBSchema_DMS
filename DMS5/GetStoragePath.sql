/****** Object:  StoredProcedure [dbo].[GetStoragePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetStoragePath
/****************************************************
**
**	Desc: Get fully-qualified storage path for instrument
**        given by @instrumentName that is currently assigned
**        to recieve new datasets.  Use client/server perspective
**        given by @clientPerspective to construct path.
**
**	Return values: 0: success, otherwise, error code
**                 @storagePath contains path
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
	(
		@instrumentName varchar(32),
		@storagePath varchar(250) OUTPUT,
		@clientPerspective int = 0
	)
As
	-- future: verify that @instrumentName in T_InstrumentName

	if @clientPerspective = 0
		begin
			-- get storage path from server perspective
			SELECT @storagePath = (SP_vol_name_server + SP_path)
			FROM t_storage_path 
			WHERE (SP_function = N'raw-storage') 
			AND (SP_instrument_name = @instrumentName)
		end
	else
		begin
			-- get storage path from client perspective
			SELECT @storagePath = (SP_vol_name_client + SP_path )
			FROM t_storage_path 
			WHERE (SP_function = N'raw-storage') 
			AND (SP_instrument_name = @instrumentName)
		end
		
	if @@rowcount <> 1 or @@error <> 0
	begin
			RAISERROR ('Could not find storage path for "%s"',
			10, 1, @instrumentName)
			return 51170
	end

	return 0
GO
GRANT VIEW DEFINITION ON [dbo].[GetStoragePath] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetStoragePath] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetStoragePath] TO [Limited_Table_Write] AS [dbo]
GO
