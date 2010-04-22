/****** Object:  StoredProcedure [dbo].[DeleteParamEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE DeleteParamEntry
/****************************************************
**
**	Desc: Deletes given Sequest Param Entry from the T_Param_Entries
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
	@paramFileID int,
	@entrySeqOrder int,
	@entryType varchar(32), 
	@entrySpecifier varchar(32),
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

	declare @ParamEntryID int
--	declare @state int
	
	declare @result int

	---------------------------------------------------
	-- get ParamFileID
	---------------------------------------------------

	set @ParamEntryID = 0
	--
	execute @ParamEntryID = GetParamEntryID @ParamFileID, @EntryType, @EntrySpecifier, @EntrySeqOrder
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not get ID for Param Entry "' + @ParamEntryID + '"'
		RAISERROR (@msg, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteParamEntry'
	begin transaction @transName
--	print 'start transaction' -- debug only

	---------------------------------------------------
	-- delete any entries for the parameter file from the entries table
	---------------------------------------------------

	DELETE FROM T_Param_Entries 
	WHERE (Param_Entry_ID = @ParamEntryID)
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete from entries table was unsuccessful for param file',
			10, 1)
		return 51130
	end	

	commit transaction @transName
	
	return 0

GO
GRANT EXECUTE ON [dbo].[DeleteParamEntry] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamEntry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamEntry] TO [PNL\D3M580] AS [dbo]
GO
