/****** Object:  StoredProcedure [dbo].[DeleteParamFileByID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE DeleteParamFileByID

(
	@ParamFileID int,
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
	
	declare @result int

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteParamFile'
	begin transaction @transName
--	print 'start transaction' -- debug only

	---------------------------------------------------
	-- delete any entries for the parameter file from the entries table
	---------------------------------------------------

	execute @result = DeleteParamEntriesForID @ParamFileID, @msg output

--	DELETE FROM T_Param_Entries 
--	WHERE (Param_File_ID = @ParamFileID)
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from entries table was unsuccessful for param file',
			10, 1)
		return 51130
	end
	
	---------------------------------------------------
	-- delete entry from dataset table
	---------------------------------------------------

    DELETE FROM T_Param_Files
    WHERE Param_File_ID = @ParamFileID

	if @@rowcount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Delete from param files table was unsuccessful for param file',
			10, 1)
		return 51136
	end
	

	commit transaction @transName
	
	return 0

GO
GRANT EXECUTE ON [dbo].[DeleteParamFileByID] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFileByID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFileByID] TO [PNL\D3M580] AS [dbo]
GO
