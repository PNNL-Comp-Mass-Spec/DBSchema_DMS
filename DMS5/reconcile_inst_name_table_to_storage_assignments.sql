/****** Object:  StoredProcedure [dbo].[ReconcileInstNameTableToStorageAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure ReconcileInstNameTableToStorageAssignments
/****************************************************
**
**	Desc: 
**     This function updates the assigned source and storage
**     path columns in the instrument name table (t_instrument_name)
**     according to the assignments given in the storage path table
**     (t_storage_path)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
As
	-- start transaction
	--
	declare @transName varchar(32)
	set @transName = 'ReconcileInstNameTableToStorageAssignments'
	begin transaction @transName

	-- set source path assignment
	--
	UPDATE T_Instrument_Name
	SET IN_source_path_ID =
		(SELECT SP_path_ID
			FROM t_storage_path
			WHERE (IN_Name = SP_instrument_name AND 
			SP_function = N'inbox'))
        
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Update was unsuccessful for t_instrument_name source',
			10, 1)
		return 51200
	end

	-- set storage path assignment
	--
	UPDATE T_Instrument_Name	
	SET IN_storage_path_ID =
		(SELECT SP_path_ID
			FROM t_storage_path
			WHERE (IN_Name = SP_instrument_name AND 
			SP_function = N'raw-storage'))       
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Update was unsuccessful for t_instrument_name storage',
			10, 1)
		return 51201
	end

	commit transaction @transName

	return 0
GO
GRANT VIEW DEFINITION ON [dbo].[ReconcileInstNameTableToStorageAssignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReconcileInstNameTableToStorageAssignments] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReconcileInstNameTableToStorageAssignments] TO [Limited_Table_Write] AS [dbo]
GO
